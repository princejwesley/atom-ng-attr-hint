ngHint = require 'ng-attr-hint'
{CompositeDisposable} = require 'atom'

module.exports =
class AtomNgAttrHintView
  decorations: []
  view: {}
  constructor: () ->
    statusBar = atom.views.getView(atom.workspace).querySelector '.status-bar'
    @statusBarElement = document.createElement('span')
    @statusBarElement.setAttribute('id', 'nghint-statusbar')
    @statusBarElement.className = 'inline-block'
    statusBar.addLeftTile({item: @statusBarElement})
    atom.workspace.onDidChangeActivePaneItem => @updateStatusBar()

  updateStatusBar: ->
    return unless @statusBarElement
    @statusBarElement.textContent = ''

    return unless editor = atom.workspace.getActiveTextEditor()
    row = editor.getCursorBufferPosition().row
    if @view?[editor.id]?.errors?[row]
      @statusBarElement.textContent = @view[editor.id].errors[row]

  updateHint: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    if @view[editor.id]?.toggle
      @destroyId editor.id
      @load editor.id

  tooltipHint: (id, message, type, row) ->
    editor = atom.workspace.getActiveTextEditor()
    element = atom.views.getView(editor)
    target = element.shadowRoot.querySelectorAll(".nghint-line-number-#{row}")
    hint = document.createElement('div')
    hint.classList.add('nghint-tooltip')
    icon = document.createElement('i')
    content = document.createElement('span')
    iconType = if type is 'warning' then 'alert' else 'info'
    icon.classList.add "icon"
    icon.classList.add "icon-#{iconType}"
    content.classList.add "nghint-content"
    content.textContent = message
    hint.appendChild(icon)
    hint.appendChild(content)

    tooltip = atom.tooltips.add(target, {
      title: hint
      placement: 'bottom'
      delay:
        show: 250
    })
    @view[id].tooltips.add(tooltip)

  onError: (err) ->
    atom.notifications.addError err

  destroyId: (id) ->
    return unless @view[id]
    container = @view[id]
    markers = container.markers
    if markers
      Object.keys(markers).forEach (key) ->
        markers[key].destroy()
    container.tooltips?.dispose()
    container.gutter?.destroy()
    if editor = atom.workspace.getActiveTextEditor()
      editor.emitter.off 'did-change-cursor-position', @view[id].statusBarCallback
      editor.emitter.off 'did-save', @view[id].updateHintCallback
    @view[id] = {}
    @statusBarElement.textContent = ''


  toggle: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    id = editor.id
    if @view[id]?.toggle
      @destroyId id
    else
      @load id

  load: (id) ->
    return unless editor = atom.workspace.getActiveTextEditor()
    @view[id] ?= { toggle: false }
    @view[id].toggle = true;
    buffer = editor.getBuffer()
    @view[id].statusBarCallback = () => @updateStatusBar()
    @view[id].updateHintCallback = () => @updateHint()
    editor.onDidChangeCursorPosition @view[id].statusBarCallback
    editor.onDidSave @view[id].updateHintCallback
    pane = atom.workspace.getActivePaneItem()
    hintPromise = ngHint(data: pane.buffer.lines.join('\n'))
    hintPromise.then @$$hint.bind({ that: this, id: id }), @onError


  # Tear down any state and detach
  destroy: ->
    Object.keys(@view).forEach (key) ->
      @destroyId(key)

  $$hint: (warnings) ->

    return unless editor = atom.workspace.getActiveTextEditor()
    {that, id} = this
    that.view[id].markers ?= {}
    that.view[id].errors ?= {}
    that.view[id].tooltips ?= new CompositeDisposable()
    if warnings?.length > 0 and editor.gutterContainer.gutterName isnt 'nghint-gutter'
      that.view[id].gutter = editor.gutterContainer.addGutter
        name: 'nghint-gutter'
        priority: -100
        visible: true

    warnings.forEach (warn) =>
      {message, type, line} = warn
      row = +line - 1
      clazz = type
      clazz = 'alert' if type is 'warning'

      item = document.createElement('div')
      item.className = 'nghint-icon'
      item.textContent = '💡 '

      marker = editor.markBufferRange([[row, 0], [row, 1]])
      editor.decorateMarker(marker, {type: 'line', class: "nghint-line"})
      editor.decorateMarker(marker, {
        type: 'gutter'
        gutterName: 'nghint-gutter'
        class: "nghint-line-number-#{row}"
        item: item
      })
      that.view[id].markers[row] = marker
      that.view[id].errors[row] = message
      setTimeout (-> that.tooltipHint(id, message, type, row)), 100
    that.updateStatusBar()
