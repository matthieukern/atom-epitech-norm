module.exports =
class EpitechNorm
  activated: false
  defaultTabLength: 0

  constructor: (@editor) ->
    @defaultTabLength = atom.config.get 'editor.tabLength'
    if (typeof @editor.getPath() != 'undefined')
      [..., fileName] = @editor.getPath().split "/"
      if atom.config.get('epitech-norm.autoActivateOnCSource')
        if fileName.match(/^.*\.[ch]$/) then @enable()
      if atom.config.get('epitech-norm.autoActivateOnMakefileSource')
        if fileName.match(/^Makefile$/) then @enable()
      if atom.config.get('epitech-norm.autoActivateOnCppSource')
        if fileName.match(/^.*\.cpp$/) then @enable()

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

  toggle: ->
    if @activated then @disable() else @enable()

  enable: ->
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
      @editor.setCursorBufferPosition([saveRow, saveCol + indentedRow.length - line.length + if line.match(/.*\r.*/) then 1 else 0])

  getIndentedRow: (lineNb) ->
    ind = 0
    last = 0
    text = @editor.getText()
    spacesBeforeArgs = 0
    skip = false
    multiLines = false
    braces = []
    parens = []
    for line in text.split("\n")
      temp = line.replace(/^\s+/, "").replace(/\r/, "")
      shift = 0

      if line.match(/.*\}.*/)
        shift = braces.pop() if braces.length > 0
        shift = braces.pop() if shift == 0 and braces.length > 0 and braces[braces.length - 1] > 0
        ind -= 1 + last + shift
        last = 0

      tmpLine = @replaceTabsBySpaces line

      if lineNb == 0 and parens.length > 0
        return "\t".repeat(parens[parens.length - 1] // 8) + " ".repeat(parens[parens.length - 1] % 8) + temp

      skip = parens.length > 0

      c = 1
      while match = (new RegExp("(?:(.*?\\\(){" + c + "})")).exec(tmpLine)
        parens.push(match[0].length)
        c += 1

      c = 1
      while match = (new RegExp("(?:(.*?\\\)){" + c + "})")).exec(tmpLine)
        parens.pop()
        c += 1

      if lineNb == 0
        ind += shift - if line.match(/.*[\{\}].*/) then last else 0
        if ind < 1
          return temp
        if line.match(/\s+[\{\}]\s*\r?/)
          ind += 0.5
        else if last
          ind -= 0.5
        return "\t".repeat((ind * 2 - 1) // 4) + "  ".repeat((ind * 2 - 1) % 4) + temp

      if line.match(/.*\{.*/)
        ind += + 1 - last
        braces.push(0)
        last = 0
      else if parens.length == 0 and line.match(/.*(if|while|for|do)\s*\(.*\).*;\s*\r?$/) or line.match(/.*else.*;\s*\r?$/)
        console.log("Condition closed")
      else if line.match(/.*else.*/) or line.match(/.*(if|while|for|do)\s*\(.*/)
        ind += 1
        if last
          braces.push(0) unless braces.length
          braces[braces.length - 1] = braces[braces.length - 1] + 1
          console.log(braces)
          ind -= 0.5
          console.log("(if|while|for|do) ind= " + ind)
        last = 1
      else
        if parens.length == 0 and not skip
            if last
              ind -= if braces.length > 0 and braces[braces.length - 1] then braces.pop() else 1
            last = 0
        if not last
          if line.match(/\=.*[^;\r][\s]*$/) or line.match(/\=.*[^;][\s]*\r$/)
            ind += 1
            multiLines = true
          else
            if multiLines
              ind -= 1
            multiLines = false

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
        @editor.setCursorBufferPosition([row + 2, 0])
        @indent e
        @editor.setCursorBufferPosition([row + 1, 0])
        @editor.moveToEndOfLine()
      else
        @editor.insertText "\n"
      @indent e
