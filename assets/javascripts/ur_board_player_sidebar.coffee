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
      @side = if @is_left then 'left' else 'right'
      @$el = $(templates['ur_board_player_sidebar']({Ur, @is_left}))
      @dice = new UrDice()
      @$captures = @$el.find('.captures')
      (@$dice = @$el.find('.dice')).append(@dice.$el)
    updateStats: (game) ->
      stats = game["#{Ur.Game.getSideName(@turn)}_stats"]
      getByKey = ($this, key) ->
        val = stats[key]
        if typeof val == 'function' then val.apply(stats) else val
      bindAttributes = (attr, f) =>
        @$el.find("[#{attr}]").each ->
          $this = $(@)
          key = $this.attr(attr)
          $this.text(f.call($this, key))
      bindAttributes 'data-stat', (key) ->
        val = stats[key]
        if typeof val == 'function' then val.apply(stats) else val
      bindAttributes 'data-dice', (key) -> stats.rolls[parseInt(key, 10)]
    updateFromGame: (game) ->
      captures = game.countCaptures(@turn)
      @dice.setDice(if game.turn == @turn then game.dice)
      @$captures.text("#{captures} capture#{if captures == 1 then '' else 's'}")
      if captures && (captures != @previous_captures)
        @$captures.addClass("flash")
        setTimeout((=> @$captures.removeClass("flash")), 10)
      @previous_captures = captures
      @updateStats(game)
