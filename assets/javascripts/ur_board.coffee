define [
  'jquery'
  'templates'
  './flash_message'
  './ur'
  './ur_grid'
  './ur_board_player_sidebar'
], (
  $
  templates
  Flash
  Ur
  UrGrid
  UrBoardPlayerSidebar
) ->

  class UrBoard
    constructor: ->
      @grid = new UrGrid
        onMove: (move, is_left)    => @listener?.onMove(move, is_left)
        onConsiderMove: (position) => @listener?.onConsiderMove(position)
      @$el = $(templates['ur_board']())
      (@$board = @$el.find('.board')).append(@grid.$el)
      @$el.find('.left_player' ).append((@left  = new UrBoardPlayerSidebar(true)).$el)
      @$el.find('.right_player').append((@right = new UrBoardPlayerSidebar(false)).$el)
      @$btnPassTurn = @$el.find('.btn_pass_turn')
      @$btnPassTurn.click => @listener?.onMove(-1)
      @$message = @$el.find('.board_message')
      @$overlay = @$el.find('.board_overlay')
      # setTimeout((=> Flash.setVisible("I'm a flash message !", true)), 1000)
      # setTimeout((=> Flash.setVisible("I'm a flash message again !", true)), 2000)
    setDisabled: (disabled) -> @$overlay.toggleClass('nodisplay', !disabled)
    setMessage: (message) -> @$message.toggleClass('nodisplay', !message).text(message)
    show: (visible = true) -> @$el[if visible then 'fadeIn' else 'fadeOut']()
    updateFromGame: (game = @game) ->
      @setMessage()
      @game = game
      @$btnPassTurn.addClass('nodisplay')
      @grid.updateFromGame(@game)
      @left.updateFromGame(game)
      @right.updateFromGame(game)
      if (winner = game.haveWinner())
        @setMessage("#{if winner == -1 then 'Left' else 'Right'} player won !")
        @setDisabled(true)
      else
        try
          moves = @game.getAvailableMoves()
          @grid.showAvailableMoveCells(moves, game.turn)
          if (moves.length == 0)
            @$btnPassTurn.removeClass('nodisplay')
          @setDisabled(false)
        catch e # Ignore errors like no turn
          @setDisabled(true)
    reset: -> @updateFromGame(new Ur.Game)
