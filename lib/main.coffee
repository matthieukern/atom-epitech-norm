{CompositeDisposable, Disposable} = require 'atom'
EpitechNorm = require('./epitech-norm')

module.exports =
  config:
    autoActivateOnCSource:
      type: 'boolean'
      default: true
    autoCheckNorm:
      type: 'boolean'
      default: false

  normByEditor: null

  activate: ->
    @normByEditor = new WeakMap

    atom.workspace.observeTextEditors (editor) =>
      return unless editor

      norm = new EpitechNorm(editor)
      @normByEditor.set(editor, norm)

      editor.onDidStopChanging () =>
        getNorm(activeEditor())?.checkNorm() if atom.config.get('epitech-norm.autoCheckNorm')

    getNorm = (e) =>
      return null unless e and @normByEditor
      return @normByEditor.get(e)

    activeEditor = () =>
      atom.workspace.getActiveTextEditor()

    atom.commands.add 'atom-workspace',
      'epitech-norm:enable': =>
        getNorm(activeEditor())?.norm()
      'epitech-norm:disable': =>
        getNorm(activeEditor())?.disable()
      'epitech-norm:indent': (e) =>
        getNorm(activeEditor())?.indent(e)
      'epitech-norm:insertTab': (e) =>
        getNorm(activeEditor())?.insertTab(e)
      'epitech-norm:newLine': (e) =>
        getNorm(activeEditor())?.insertNewLine(e)
      'epitech-norm:checkNorm': (e) =>
        getNorm(activeEditor())?.checkNorm(e)