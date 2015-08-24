AtomNgAttrHintView = require './atom-ng-attr-hint-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomNgAttrHint =
  atomNgAttrHintView: null
  subscriptions: null
  activate: (state) ->
    @atomNgAttrHintView = new AtomNgAttrHintView()
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-ng-attr-hint:toggle': => @toggle()

  deactivate: ->
    @subscriptions?.dispose()
    @atomNgAttrHintView?.destroy()

  toggle: ->
    @atomNgAttrHintView?.toggle()
