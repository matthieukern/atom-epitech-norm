module.exports =
class EpitechNormChecker
  text: null
  fileType: null
  isInFunc: false
  funcLines: 0
  funcNum: 0
  lineNum: 0

  markers: []

  constructor: (@editor) ->

  warn: (msg, row, col, length) ->
#    console.log "Norm error line " + row + ": " + msg
    marker = @editor.markBufferRange([[row, col], [row, col + length]], invalidate: 'inside')
    @editor.decorateMarker(marker, {type: 'highlight', class: 'norm-error'})
    @markers.push(marker)

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

  check: ->
    [..., fileName] = @editor.getPath().split "/"
    @fileType = "c" if fileName.match /^.*\.[c]$/
    @fileType = "h" if fileName.match /^.*\.[h]$/
    @fileType = "mk" if fileName.match /^[Mm]akefile$/

    for marker in @markers
      marker.destroy()

    @funcNum = 0
    @funcLines = 0
    @isInFunc = false
    @lineNum = 0
    @text = @editor.getText().split "\n"
    for line in @text
      @checkFuncScope line
      @checkLineLength line
      @checkEndlineSpaces line
      @checkSpacesParen line
      @checkKeyWordsSpaces line
      @checkEndLineSemicolon line
      @checkComment line
      @lineNum += 1

  checkFuncScope: (line) ->
    if @fileType == "c"
      if line.match /^\}.*$/
        @isInFunc = false
        @funcLines = 0
      if line.match /^\{.*$/
        @isInFunc = true
        @funcLines = 0
        @funcNum += 1
        @warn("More than 5 functions in the file.", @lineNum - 1, 0, @text[@lineNum - 1].length) if @funcNum > 5
        @checkFuncVars()
      else if @isInFunc and @funcNum > 0
        @funcLines += 1
      @warn("Function of more than 25 lines.", @lineNum, 0, line.length) if @funcLines > 25

  checkFuncVars: ->
    i = @lineNum - 1
    while not @text[i].match /^[^\s]/
      i -= 1
    funLine = @replaceTabsBySpaces @text[i]
    tabSize = funLine.match /^(.*?)[^\s]+\(.*$/
    tabSize = tabSize[1].length
    i = @lineNum + 1
    while !(i >= @text.length or @text[i].match /^\s*$/)
      if @text[i].match /^}.*$/
        return
      i += 1
    if i >= @text.length
      return
    i = @lineNum + 1
    while !(@text[i].match /^\s*$/)
      varLine = @replaceTabsBySpaces @text[i]
      varSize = varLine.match /^(.*?)[^\s]+$/
      if varSize
        varSize = varSize[1].length
        @warn("Function and var name aren't aligned.", i, 0, @text[i].length) if varSize != tabSize
      i += 1

  checkLineLength: (line) ->
    tmp = @replaceTabsBySpaces line
    if tmp.length > 80
      @warn("Line of more than 80 characters.", @lineNum, 0, line.length)

  checkEndlineSpaces: (line) ->
    tmp = line.match /\s+$/
    if tmp
      @warn("Space at the end of the line.", @lineNum, tmp.index, line.length - tmp.index)

  checkEndLineSemicolon: (line) ->
    tmp = line.match /\s+$;/
    if tmp
      @warn("Space before semicolon at end of line", @lineNum, tmp.index, line.length - tmp.index)

  checkSpacesParen: (line) ->
    if @fileType == "c" or @fileType == "h"
      i = 0
      quote = false
      while i < line.length and line.charAt i != '\n'
        ch = line.charAt i
        prev = line.charAt i - 1
        next = line.charAt i + 1
        if (ch == '\'' or ch == '"') and (i > 0 and prev != '\\' or i == 0)
          quote = not quote
        if not quote
          if ch == '('
            @warn("Space after open paren.", @lineNum, i, 2) if next == ' ' or next == '\t'
          if ch == ')'
            @warn("Space before close paren.", @lineNum, i - 1, 2) if prev == ' ' or prev == '\t'
        i += 1

  checkKeyWordsSpaces: (line) ->
    tmp = line.match /(if|else|return|while|for)\(/
    @warn("Missing space after a keyword.", @lineNum, tmp.index, tmp[0].length) if tmp

  checkComment: (line) ->
    tmp = line.match /(\/\/.*)/
    if tmp
      @warn("C++ style comment!", @lineNum, tmp.index, line.length - tmp.index)
    tmp = line.match /(\/\*(?:(?!\*\/).)*(?:\*\/)?)/
    if @isInFunc and tmp
      @warn("Comment in function.", @lineNum, tmp.index, tmp[1].length)
