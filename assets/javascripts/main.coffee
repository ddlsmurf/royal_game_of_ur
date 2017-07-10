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

    rushAI = (moves) -> moves[moves.length - 1]
    makeAIPlayerController = (ai) ->
      yourTurn: (controller, game) ->
        moves = game.getAvailableMoves()
        move = switch moves.length
          when 0
            -1
          when 1
            moves[0]
          else
            ai(moves)
        setTimeout((-> controller.playMove(move)), 300)

    showBoard = (visible) ->
      $("#start_game_section").toggleClass('nodisplay', visible)
      $restartButton.toggleClass("nodisplay", !visible)
      board.show(visible)

    startGame = (online, ai) ->
      UrTutorial.end()
      setTutorialStarted(false)
      game_listener =
        onGameChange: (game, playerController) ->
          board.updateFromGame(game)
          board.setDisabled(playerController?) if game.turn
      controller = new Ur.GameController(new Ur.Game(), game_listener,
        null, #makeAIPlayerController(rushAI),
        if ai? then makeAIPlayerController(ai))
      board.listener =
        onMove: (position, is_left) ->
          return if is_left? && (is_left != (controller.game.turn == -1))
          controller.playMove(position)
          board
      showBoard(true)

    $startGameLocal  = $("#btn_start_game_local_human").click -> startGame(false)
    $startGameAIEasy = $("#btn_start_game_ai_easy").    click -> startGame(false, rushAI)
    $startGameAIHard = $("#btn_start_game_ai_hard").    click -> startGame(false, rushAI)
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
