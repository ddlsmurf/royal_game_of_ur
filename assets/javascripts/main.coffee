require
  # urlArgs: "b=#{(new Date()).getTime()}"
  paths:
    jquery: 'vendor/jquery/jquery'
    bluebird: 'vendor/bluebird/bluebird'
    lodash: 'vendor/lodash/lodash'
    _: 'vendor/lodash/lodash'
    promise: 'vendor/bluebird/bluebird'
    bootstrap: 'vendor/bootstrap/bootstrap.min'
  shim: {
    'bootstrap': deps: ['jquery']
  }, [
    'jquery'
    'templates'
    'bootstrap'
    './ur'
    './ur_board'
    './ur_tutorial'
  ], (
    $
    templates
    bootstrap
    Ur
    UrBoard
    UrTutorial
  ) ->
    $("#content").html(templates['main']())
    window.board = board = new UrBoard
    $("#content").append(board.$el)
    controller = null

    showBoard = (visible) ->
      $("#start_game_section").toggleClass('nodisplay', visible)
      $restartButton.toggleClass("nodisplay", !visible)
      board.show(visible)

    startGame = (online, ai) ->
      UrTutorial.end()
      setTutorialStarted(false)
      game_listener =
        onGameChange: (game, playerController, expectedMove) ->
          board.updateFromGame(game)
          if game.turn
            board.setDisabled(playerController?)
            board.grid.showPath(expectedMove, game.getDiceValue(), game.turn == -1) if expectedMove? && expectedMove != -1
      controller = new Ur.GameController(game_listener,
        null, #Ur.AI.toController(rushAI, 700),
        if ai? then Ur.AI.toController(ai, 700))
      board.listener =
        onMove: (position, is_left) ->
          return if is_left? && (is_left != (controller.game.turn == -1))
          controller.playMove(position)
          board
        onConsiderMove: (position) ->
          game = controller.game
          if position? && game.turn
            board.grid.showPath(position, game.getDiceValue(), game.turn == -1)
          else
            board.grid.clearPath()
      showBoard(true)

    $startGameLocal  = $("#btn_start_game_local_human").click -> startGame(false)
    $startGameAIEasy = $("#btn_start_game_ai_easy").    click -> startGame(false, Ur.AI.rush)
    $startGameAIMid  = $("#btn_start_game_ai_avg").     click -> startGame(false, Ur.AI.middle)
    $startGameAIHard = $("#btn_start_game_ai_hard").    click -> startGame(false, Ur.AI.hard)
    $startGameRemote = $("#btn_start_game_remote").     click -> startGame(true)

    $restartButton = $("#btn_restart").click ->
      controller?.abort()
      controller = null
      board.listener = null
      showBoard(false)

    moveTutorial = (method, a...) ->
      UrTutorial[method](a...)
      $prevTutorialButton.prop disabled: !UrTutorial.hasPrev()
      $nextTutorialButton.prop disabled: !UrTutorial.hasNext()

    $prevTutorialButton = $("#btn_tutorial_prev").click -> moveTutorial('prev')
    $nextTutorialButton = $("#btn_tutorial_next").click -> moveTutorial('next')

    setTutorialStarted = (started) ->
      $startTutorialButton.toggleClass('nodisplay', started)
      $prevTutorialButton.toggleClass('nodisplay', !started)
      $nextTutorialButton.toggleClass('nodisplay', !started)

    $startTutorialButton = $("#btn_tutorial_start").click ->
      setTutorialStarted(true)
      moveTutorial('start', $("#tutorial"), board)


    # setTimeout((-> $startGameLocal.click()), 100)
    # setTimeout((-> $startGameAIEasy.click()), 100)
    # setTimeout((-> $startGameAIHard.click()), 100)
    # setTimeout((-> $startGameRemote.click()), 100)
    # setTimeout((-> $startTutorialButton.click()), 100)
    # setTimeout((-> $nextTutorialButton.click()), 200)
    # setTimeout((-> $nextTutorialButton.click()), 300)
    # setTimeout((-> $nextTutorialButton.click()), 400)
    # setTimeout((-> $nextTutorialButton.click()), 500)
    # setTimeout((-> $nextTutorialButton.click()), 600)
    # setTimeout((-> $nextTutorialButton.click()), 700)
    # setTimeout((-> $nextTutorialButton.click()), 800)
    # setTimeout((-> $nextTutorialButton.click()), 900)
    # setTimeout((-> $nextTutorialButton.click()), 1000)
