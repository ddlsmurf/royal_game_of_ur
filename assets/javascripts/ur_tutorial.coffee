define [
  'jquery'
  'templates'
  './ur'
  './ur_dice'
  './ur_grid'
], (
  $
  templates
  Ur
  UrDice
  UrGrid
) ->
  $container = null
  board = null
  pageNumber = null
  onQuitPage = null
  initialHTML = null

  quitPage = ->
    $container?.html("")
    if onQuitPage?
      onQuitPage()
      onQuitPage = null
    pageNumber = null

  showPage = (num) ->
    initialHTML = $container.html() ? "" unless initialHTML?
    quitPage()
    if "ur_tutorial_page_#{num}" of templates
      $container.html(templates["ur_tutorial_page_#{num}"]({Ur, templates}))
      pageStartup[num]($container) if num of pageStartup
      pageNumber = num

  pageStartup =
    '0': ($el) ->
      dice = new UrDice()
      dice.randomizeDice()
      ($dice = $el.find('.dice_tutorial')).append(dice.$el)
      interval = setInterval(( -> dice?.randomizeDice() ), 3000)
      board.show(false)
      onQuitPage = ->
        clearInterval(interval) if interval?
        dice = interval = null
    '1': ->
      board.show(true)

      interval = setInterval(( ->
        return unless interval?
        is_left = (Math.random() > 0.8)
        board[if !is_left then 'left' else 'right'].dice.setDice("Waiting for other player...")
        board[if  is_left then 'left' else 'right'].dice.randomizeDice()
      ), 700)
      onQuitPage = ->
        clearInterval(interval) if interval?
        interval = null
        board.left.dice.setDice()
        board.right.dice.setDice()
    '2': ->
      board.reset()
      board.setDisabled(false)
      board.grid.flashSpecialCells('starter')
      onQuitPage = -> board.grid.flashSpecialCells()
    '3': ->
      is_left = true
      interval = setInterval(( ->
        return unless interval?
        board.grid.showPath(0, 15, is_left)
        is_left = !is_left
      ), 700)
      board.grid.flashSpecialCells('ender')
      onQuitPage = ->
        clearInterval(interval) if interval?
        interval = null
        board.grid.flashSpecialCells()
        board.grid.clearPath()
    '4': ->
      board.grid.flashSpecialCells('rethrow')
      onQuitPage = -> board.grid.flashSpecialCells()
    '5': ->
      board.reset()
      board.setDisabled(false)
      board.grid.flashSpecialCells('tutorial_5_capture_example')
      board.game.turn = -1
      interval = setInterval(( ->
        return unless interval?
        if board.game.dice?
          dice = board.game.dice
          piece = board.game.findFurthestPiece(board.game.turn)
          board.game.playMove(piece) if piece >= 0
          board.grid.clearPath()
        else
          board.game.throwDiceCheating(2)
          piece = board.game.findFurthestPiece(board.game.turn)
          board.grid.showPath(piece, board.game.getDiceValue(), board.game.turn == -1)
        board.updateFromGame(board.game)
        board.setDisabled(false)
        if board.game.left_indices[0] == 10 || board.game.right_indices[0] == 10
          board.reset()
          board.game.turn = -1
          board.setDisabled(false)
      ), 1000)
      onQuitPage = ->
        clearInterval(interval) if interval?
        board.grid.flashSpecialCells()
        board.grid.clearPath()
        interval = null
        board.reset()
    '6': ->
      board.reset()
      board.setDisabled(false)
      board.grid.flashSpecialCells('safe')
      onQuitPage = -> board.grid.flashSpecialCells()
    '7': ->
      board.updateFromGame(new Ur.Game(Ur.Game.ExampleStates.stuckByPositions))
      onQuitPage = ->
        board.reset()
        board.setDisabled(false)
    '8': ->
      board.updateFromGame(new Ur.Game(Ur.Game.ExampleStates.stuckByDice))
      onQuitPage = ->
        board.reset()
        board.setDisabled(false)



  start: ($el, newBoard) ->
    board = newBoard
    $container = $el
    showPage(0)

  prev: -> showPage(Math.max(0, pageNumber - 1))
  next: -> showPage(pageNumber + 1)
  hasPrev: -> pageNumber > 0
  hasNext: -> "ur_tutorial_page_#{pageNumber + 1}" of templates

  end: ->
    quitPage()
    $container?.html(initialHTML)
