{CompositeDisposable, Disposable} = require 'atom'
EpitechNorm = require('./epitech-norm')

module.exports =
  config:
    autoActivateOnCSource:
      type: 'boolean'
      default: true
    autoActivateOnMakefileSource:
      type: 'boolean'
      default: true
    autoActivateOnCppSource:
      type: 'boolean'
      default: true

  normByEditor: null

  activate: ->
    @normByEditor = new WeakMap

    atom.workspace.observeTextEditors (editor) =>
      return unless editor

      norm = new EpitechNorm(editor)
      @normByEditor.set(editor, norm)

    getNorm = (e) =>
      return null unless e and @normByEditor
      return @normByEditor.get(e)

    activeEditor = () =>
      atom.workspace.getActiveTextEditor()

    atom.commands.add 'atom-workspace',
      'epitech-norm:toggle': =>
        getNorm(activeEditor())?.toggle()
      'epitech-norm:indent': (e) =>
        getNorm(activeEditor())?.indent(e)
      'epitech-norm:insertTab': (e) =>
        getNorm(activeEditor())?.insertTab(e)
      'epitech-norm:newLine': (e) =>
        getNorm(activeEditor())?.insertNewLine(e)
