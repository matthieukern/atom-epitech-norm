module.exports =
class EpitechNorm
  activated: false
  defaultTabLength: 0

  constructor: (@editor) ->
    @defaultTabLength = atom.config.get 'editor.tabLength'
    [..., fileName] = @editor.getPath().split "/"
    if atom.config.get('epitech-norm.autoActivateOnCSource')
      if fileName.match /^.*\.[ch]$/ then @norm()

  replaceTabsBySpaces: (str) ->
    i = 0
    ret = ""
    for ch in str
      if ch == '\t'
        ret += " ".repeat(8 - i % 8)
        i += 8 - i % 8
      else
        ret += ch
        i += 1
    return ret

  norm: ->
    @activated = true
    @editor.setTabLength 8

  disable: ->
    @activated = false
    @editor.setTabLength @defaultTabLength

  indent: (e) ->
    unless @activated or @editor.hasMultipleCursors()
      e.abortKeyBinding() if e
      return

    @editor.transact =>
      [saveRow, saveCol] = @editor.getCursorBufferPosition().toArray()
      @editor.moveToEndOfLine()
      [row, col] = @editor.getCursorBufferPosition().toArray()
      line = @editor.getText().split("\n")[row]
      indentedRow = @getIndentedRow row
      @editor.setTextInBufferRange([[row, 0], [row, col]], indentedRow)
      @editor.setCursorBufferPosition([saveRow, saveCol + indentedRow.length - line.length])

  getIndentedRow: (lineNb) ->
    ind = 0
    last = 0
    text = @editor.getText()
    spacesBeforeArgs = 0
    braces = []
    for line in text.split "\n"
      temp = line.replace(/^\s+/, "")
      shift = 0

      if line.match /.*\}.*/
        shift = braces.pop() if braces.length > 0
        shift = braces.pop() if shift == 0 and braces.length > 0 and braces[braces.length - 1] > 0
        ind -= 1 + last + shift
        last = 0

      tmpLine = @replaceTabsBySpaces line
      tmp = tmpLine.match /^(.*?[^\s]+\().*$/
      if tmp and ind == 0
        spacesBeforeArgs = tmp[1].length

      else if lineNb == 0 and spacesBeforeArgs > 0 and ind == 0
        if tmpLine.match /^[^{]/
          return "\t".repeat(spacesBeforeArgs // 8) + " ".repeat(spacesBeforeArgs % 8) + temp

      if lineNb == 0
        ind += shift - if line.match /.*[{}].*/ then last else 0
        return "\t".repeat(ind // 4) + "  ".repeat(ind % 4) + temp

      if line.match /.*\{.*/
        spacesBeforeArgs = 0
        ind += + 1 - last
        braces.push(0)
        last = 0
      else if line.match /.*(if|while|for|do|else)\s*\(.*/
        ind += 1
        if last
          braces.push(0) unless braces.length
          braces[braces.length - 1] = braces[braces.length - 1] + 1
        last = 1
      else
        if last
          ind -= if braces.length > 0 and braces[braces.length - 1] then braces.pop() else 1
        last = 0

      lineNb = lineNb - 1
    return ""

  insertTab: (e) ->
    unless @activated
      e.abortKeyBinding() if e
      return
    @editor.insertText '\t'

  insertNewLine: (e) ->
    unless @activated
      e.abortKeyBinding() if e
      return

    @editor.transact =>
      [row, col] = @editor.getCursorBufferPosition().toArray()
      line = @editor.getText().split("\n")[row]

      if line.charAt(col - 1) is '{' and line.charAt(col) is '}'
        @editor.insertText "\n\n"
        @indent e
        @editor.setCursorBufferPosition([row, 0])
        @indent e
        @editor.setCursorBufferPosition([row + 1, 0])
        @editor.moveToEndOfLine()
      else
        @editor.insertText "\n"
      @indent e
