module.exports =
class EpitechNorm
  activated: false
  defaultTabLength: 0

  constructor: (@editor) ->
    @defaultTabLength = atom.config.get 'editor.tabLength'
    [..., fileName] = @editor.getPath().split "/"
    if atom.config.get('epitech-norm.autoActivateOnCSource')
      if fileName.match /^.*\.[ch]$/ then @norm()

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

    @editor.moveToEndOfLine()
    [row, col] = @editor.getCursorBufferPosition().toArray()
    @editor.setTextInBufferRange([[row, 0], [row, col]], @getIndentedRow row)
    @editor.moveToEndOfLine()

  getIndentedRow: (lineNb) ->
    ind = 0
    last = 0
    text = @editor.getText()
    braces = []
    for line in text.split "\n"
      temp = line.replace(/^\s+/, "")
      shift = 0

      if line.match /.*\}.*/
        shift = braces.pop() if braces.length > 0
        shift = braces.pop() if shift == 0 and braces.length > 0 and braces[braces.length - 1] > 0
        ind -= 1 + last + shift
        last = 0

      if lineNb == 0
        ind += shift - if line.match /.*[{}].*/ then last else 0
        return "\t".repeat(ind // 4) + "  ".repeat(ind % 4) + temp

      if line.match /.*\{.*/
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
    @editor.insertText "\t"

  insertNewLine: (e) ->
    unless @activated
      e.abortKeyBinding() if e
      return
    @editor.insertText "\n"
    @indent e
