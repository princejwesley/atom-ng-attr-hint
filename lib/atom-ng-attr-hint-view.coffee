ngHint = require 'ng-attr-hint'
{CompositeDisposable} = require 'atom'

module.exports =
class AtomNgAttrHintView
  decorations: []
  view: {}
  constructor: () ->

  #TODO status bar

  tooltipHint: (id, message, type, row) ->
    console.log('tooltip selector', ".nghint-line-number.line-number-#{row}" )

    editor = atom.workspace.getActiveTextEditor()
    element = atom.views.getView(editor)
    target = element.shadowRoot.querySelectorAll(".nghint-line-number.line-number-#{row}")
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
    console.log('target', target)
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
    console.log('destroy id', id)
    return unless @view[id]
    markers = @view[id].markers
    if markers
      Object.keys(markers).forEach (key) ->
        markers[key].destroy()
    @view[id].tooltips?.dispose()
    @view[id] = {}

  toggle: ->
    return unless editor = atom.workspace.getActiveTextEditor()

    console.log('id', editor.id)
    id = editor.id
    if @view[id]?.toggle
      @destroyId(editor.id);
    else
      @view[id] ?= { toggle: false }
      @view[id].toggle = true;
      pane = atom.workspace.getActivePaneItem()
      hintPromise = ngHint(data: pane.buffer.lines.join('\n'))
      hintPromise.then @hint.bind({ that: this, id: id }), @onError

  # Tear down any state and detach
  destroy: ->
    console.log('destroy')
    Object.keys(@view).forEach (key) ->
      @destroyId(key)

  hint: (warnings) ->
    console.log('hint')
    return unless editor = atom.workspace.getActiveTextEditor()
    {that, id} = this
    console.log('that', that, 'id', id)
    console.log warnings
    that.view[id].markers ?= {}
    that.view[id].tooltips ?= new CompositeDisposable()
    warnings.forEach (warn) =>
      {message, type, line} = warn
      console.log(message, type,line)
      row = +line - 1
      marker = editor.markBufferRange([[row, 0], [row, 1]])
      editor.decorateMarker(marker, {type: 'line', class: "nghint-line"})
      editor.decorateMarker(marker, {type: 'line-number', class: "nghint-line-number"})
      that.view[id].markers[row] = marker
      setTimeout (-> that.tooltipHint(id, message, type, row)), 100
