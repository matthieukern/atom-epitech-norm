{CompositeDisposable, Disposable} = require 'atom'
EpitechNorm = require('./epitech-norm')

module.exports =

  normByEditor: null

  activate: ->
    @normByEditor = new WeakMap

    atom.workspace.observeTextEditors (editor) =>
      return unless editor

      norm = new EpitechNorm(editor)
      @normByEditor.set(editor, norm)

    getNorm = (e) =>
      @normByEditor.get(e)

    activeEditor = () =>
      atom.workspace.getActiveTextEditor()

    atom.commands.add 'atom-text-editor:not([mini])',
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
