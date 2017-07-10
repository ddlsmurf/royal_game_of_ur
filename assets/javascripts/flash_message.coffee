define [
  'jquery'
], (
  $
) ->
  class Flash
    constructor: (@$el) ->
      @$el = $("<div class='flash_message'>").append(@$txt = $("<span>"))
      $("body").append(@$el)
    setVisible: (visible, autoHide) ->
      clearTimeout(@autoHide) if @autoHide
      delete @autoHide
      @visible = !!visible
      @$txt.text(visible) if visible
      @$el.toggleClass('visible', !!visible)
      if visible && autoHide
        @autoHide = setTimeout((=>
          delete @autoHide
          @setVisible(false)
        ), 3000)
  new Flash