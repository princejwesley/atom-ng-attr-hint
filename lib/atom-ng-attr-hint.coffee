AtomNgAttrHintView = require './atom-ng-attr-hint-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomNgAttrHint =
  atomNgAttrHintView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomNgAttrHintView = new AtomNgAttrHintView(state.atomNgAttrHintViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomNgAttrHintView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-ng-attr-hint:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomNgAttrHintView.destroy()

  serialize: ->
    atomNgAttrHintViewState: @atomNgAttrHintView.serialize()

  toggle: ->
    console.log 'AtomNgAttrHint was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
