define [
  'jquery'
  'templates'
  './flash_message'
  './ur'
  './ur_dice'
], (
  $
  templates
  Flash
  Ur
  UrDice
) ->
  class UrBoardPlayerSidebar
    constructor: (@is_left) ->
      @turn = if @is_left then -1 else 1
      @$el = $(templates['ur_board_player_sidebar']({@is_left}))
      @dice = new UrDice()
      @$captures = @$el.find('.captures')
      (@$dice = @$el.find('.dice')).append(@dice.$el)
    updateFromGame: (game) ->
      captures = game.countCaptures(@turn)
      @dice.setDice(if game.turn == @turn then game.dice)
      @$captures.text("#{captures} capture#{if captures == 1 then '' else 's'}")
      if captures && (captures != @previous_captures)
        @$captures.addClass("flash")
        setTimeout((=> @$captures.removeClass("flash")), 10)
      @previous_captures = captures