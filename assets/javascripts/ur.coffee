define [
], (
) ->
  getRandomIntIncMinExcMax = (min, max) -> Math.floor(Math.random() * (max - min)) + min
  # Base UR module.
  #
  # *Not actually a mixin, but codo wouldn't document this otherwise.*
  # @mixin
  # @example thing
  Ur =
    PositionDisputeStart: 5
    PositionDisputeEnd: 12
    PositionMax: 16
    DiceCount: 4
    DicePositions: 6
    SpecialCellPositions:
      rethrow: [4, 8, 14]
      safe: [8]
    # Intial number of tokens
    TokenCount: 7
    # Return new random set of dice positions
    # @return {Array<Integer, DiceCount>} {Ur.DiceCount} integers
    getRandomDice: -> getRandomIntIncMinExcMax(0, @DicePositions) for i in [0...@DiceCount]
    # Count value of provided array of dice. A dice is worth 1 if odd.
    # @param dice {Array<Integer, DiceCount>} {Ur.DiceCount} integers
    getDiceValue: (dice) ->
      total = 0
      total += 1 for i in [0...@DiceCount] when (dice[i] & 1) == 1
      total
    # Throw an error unless `p` is a valid position on the board, including start and end cells
    # @param p {Integer} Position index on the board (see {Ur~getXYFromPosition})
    checkPositionIndex: (p) -> throw new Error("Invalid move #{JSON.stringify(p)}") unless 0 <= p < @PositionMax
    ###
    Convert board index to `x,y` coordinates.

    @param p {Integer} Position index on the board (see {Ur~getXYFromPosition})
    @param is_left {Boolean} `true` to return the coordinates for left player, `false` for the right player.
    @example Board layout and indexes
          |   0   1    2
        --+--------------
        0 |  d4   5   d4
        1 |   3   6    3
        2 |   2   7    2
        3 |   1  x8    1
        4 |(s 0)  9 (s 0)
        5 |(e15) 10 (e15)
        6 | d14  11  d14
        7 |  13  12   13
    ###
    getXYFromPosition: (p, is_left) ->
      @checkPositionIndex(p)
      x = if p < @PositionDisputeStart || p > @PositionDisputeEnd
            if is_left then 0 else 2
          else
            1
      y = if p < @PositionDisputeStart
            4 - p
          else if p == @PositionDisputeEnd
            7
          else if p > @PositionDisputeEnd
            7 - (p - @PositionDisputeEnd - 1)
          else
            p - @PositionDisputeStart
      [x, y]
    # Return an object with keys set if the cell at `X,Y` has special properties.
    # @return [Object] Object with a set of keys from `safe` and/or `rethrow`
    getCellProperties: (x, y) ->
      [p, is_left] = @getPositionFromXY(x, y)
      result = if p == 0 then { starter: true } else (if p == @PositionMax - 1 then { ender: true } else { cell: true} )
      result[prop] = true for prop in ['safe', 'rethrow'] when @SpecialCellPositions[prop].indexOf(p) >= 0
      result
    # Return board index position from `X,Y` coordinates, and side if possible.
    # @return [Array<Integer, Boolean>] Returns the board index, and undefined, or a boolean for which `true` is left, and `false` right.
    getPositionFromXY: (x, y) ->
      is_left = if x == 1 then undefined else (x == 0)
      p = if x == 1
            y + @PositionDisputeStart
          else
            if y < 5
              4 - y
            else
              @PositionDisputeEnd + 7 + 1 - y
      [p, is_left]
    Colors:
      left: 'blue'
      right: 'red'
  ###
    Takes a `Ur.Game`, and optional player controllers, and fowards the game along.
  ###
  Ur.GameController = class UrGameController
    ###
    Events:

    - listener:
        - `onGameChange: function (game, controller, expectedMove)`: called at the start
          and whenever it is a new player's turn. If the player has a controller,
          `expectedMove` is the result of calling that controller's AI, if any.
    - player controller:
        - `yourTurn: function(gameController, game)`: called whenever it is that player's
          turn. Can return an expected move for display, but should asynchronously call
          `gameController.playMove`. Call can be synchroneous if `listener.onGameChange` is ignored.

    @param [Object] listener Listener for game state changes
    @param [Object] leftPlayerController Listener for handling a player's turn, see above.
    @param [Object] rightPlayerController See `leftPlayerController` above.
    ###
    constructor: (@listener, @leftPlayerController, @rightPlayerController) ->
      @game = new Ur.Game()
      @reset()
    getPlayerController: (turn = @game.turn) -> if turn == -1 then @leftPlayerController else (if turn == 1 then @rightPlayerController)
    ###
    @private
    ###
    __onNewTurn: (skipThrowDice) ->
      if (turn = @game.turn)
        controller = @getPlayerController(turn)
        @game.throwDice() unless skipThrowDice
        if controller?
          expectedMove = controller.yourTurn(@, @game)
      @listener.onGameChange(@game, controller, expectedMove)
    ###
    Prevent any more moves
    ###
    abort: -> @aborted = true
    ###
    Advance game by playing given move
    @param [Number] move Cell number to move from, or -1 to pass turn
    ###
    playMove: (move) ->
      throw new Error("Game aborted") if @aborted
      @game.playMove(move)
      @__onNewTurn()
    ###
    Reset game state to start, pick random first player, and throw dice.
    ###
    reset: ->
      delete @aborted
      @game.reset()
      @game.turn = (getRandomIntIncMinExcMax(0, 2) && 1) || -1
      @__onNewTurn()

  Ur.GamePlayerStats = class UrGamePlayerStats
    constructor: (state) -> if state? then @safeLoadFromArray(state) else @reset()
    reset: -> @safeLoadFromArray([ 0, 0, [], 0, 0 ])
    validateGameState: ->
    loadFromArray: (data) -> [ @captures, @rethrows, @rolls, @wasted, @blocks, @was_first ] = data
    writeToArray:         -> [ @captures, @rethrows, @rolls, @wasted, @blocks, @was_first ]
    safeLoadFromArray: (data) ->
      @loadFromArray(data)
      @validateGameState()
    didRethrow: -> @rethrows += 1
    didPlayTurn: (currentPlayer, dice, move, destination, didCapture) ->
      @was_first ?= currentPlayer
      if currentPlayer
        @rolls[dice] = (@rolls[dice] ? 0) + 1
        @captures += 1 if didCapture
        @blocks += 1 if move == -1
        @wasted += waste if move >= 0 && (waste = ((move + dice) - destination)) > 0

    getTotalThrows: -> @rolls.reduce(((sum, e, i) -> sum + (i * (e ? 0))), 0)
    getThrowCount: -> @rolls.reduce(((sum, e) -> sum + (e ? 0)), 0)
    getBlockedWithoutDice: -> @blocks - (@rolls[0] ? 0)
  ###
  Represents the state of a game, some analysis methods on it, and serialisation
  ###
  Ur.Game = class UrGame
    @ExampleStates:
      stuckByPositions: [ -1, [ 0, 1, 2, 3 ], [ 1, 2, 4, 6 ], [ 0, 8 ], [ 0, 0 ] ]
      stuckByDice:      [  1, [ 0, 2, 4, 0 ], [ 6, 2 ],       [ 5, 4 ], [ 0, 0 ] ]
    ###
    @param [Array] state See `loadFromArray`
    ###
    constructor: (state) ->
      @left_stats  = new Ur.GamePlayerStats
      @right_stats = new Ur.GamePlayerStats
      if state? then @safeLoadFromArray(state) else @reset()
    ###
    Set game state to unstarted empty board
    ###
    reset: -> @safeLoadFromArray([0, null, [ Ur.TokenCount ], [ Ur.TokenCount ], [ 0, 0 ] ])
    ###
    Ensure internal game state is consistent
    ###
    validateGameState: ->
      validateTokens = (side, remaining, indices) ->
        throw new Error("Invalid game state (#{side}_remaining #{JSON.stringify(remaining)})") unless 0 <= remaining <= Ur.TokenCount
        throw new Error("Invalid game state (#{side}_indices #{JSON.stringify(indices)})") unless indices.every((v) -> 0 < v < Ur.PositionMax - 1)
        total = remaining + indices.length
        throw new Error("Invalid game state (#{side}_total #{total} = #{JSON.stringify(remaining)} + #{JSON.stringify(indices)})") unless 0 <= total <= Ur.TokenCount

      throw new Error("Invalid game state (turn #{JSON.stringify(@turn)})") unless @turn in [-1, 0, 1]
      throw new Error("Invalid game state (left_captures #{JSON.stringify(@left_captures)})") if typeof @left_captures != 'number'
      throw new Error("Invalid game state (right_captures #{JSON.stringify(@right_captures)})") if typeof @right_captures != 'number'
      if @dice?
        throw new Error("Invalid game state (dice #{JSON.stringify(@dice)})") if @dice.length != Ur.DiceCount
        throw new Error("Invalid game state (dice #{JSON.stringify(@dice)})") unless @dice.every((v) -> 0 <= v < Ur.DicePositions)
      validateTokens('left', @left_remaining, @left_indices)
      validateTokens('right', @right_remaining, @right_indices)
      throw new Error("Invalid game state (dup idx #{JSON.stringify({@left_indices, @right_indices})})") for l in @left_indices when @right_indices.indexOf(l) > 0
      @
    @getSideName: (side) ->
      return (if side then -1 else 1) if typeof side is 'boolean'
      if typeof side is 'number' then (if side == -1 then 'left' else if side == 1 then 'right') else side
    getSideNames: -> Ur.Game.getSideNames(@turn)
    @getSideNames: (side) ->
      throw new Error("Invalid side #{side}") unless side in [-1, 1]
      [ Ur.Game.getSideName(side), Ur.Game.getSideName(if side == -1 then 1 else -1) ]
    @otherTurn: (turn) -> if turn == -1 then 1 else (if turn == 1 then -1)
    otherTurn: (required) ->
      throw new Error("No current turn") unless (!required) || (@turn)
      Ur.Game.otherTurn(@turn)
    countCaptures: (side) ->
      @["#{Ur.Game.getSideName(side)}_stats"].captures
    countTokensLeft: (side) ->
      side = Ur.Game.getSideName(side)
      @["#{side}_remaining"] + @["#{side}_indices"].length
    countTokensSafe: (side) -> Ur.TokenCount - @countTokensLeft(side)
    ensureSorted: ->
      @left_indices.sort((a, b) -> b - a)
      @right_indices.sort((a, b) -> b - a)
      @
    findFurthestPiece: (side) ->
      side = Ur.Game.getSideName(side)
      @ensureSorted()
      list = @["#{side}_indices"]
      if list.length > 0 then list[list.length - 1] else (if @["#{side}_remaining"] > 0 then 0 else -1)
    ###
    @return [number] Current dice value
    ###
    getDiceValue: -> Ur.getDiceValue(@dice)
    ###
    @param [number] side Side whose attack risk is to be evaluated
    @return [number] Array of risk probabilities
    ###
    getAttackRiskMap: (side) -> # get probability by position of <side> putting a token on disputable cell
      [ our_side, their_side ] = @getSideNames(side)
      list = @["#{our_side}_indices"]
      list_theirs = @["#{their_side}_indices"]
      result = (0 for i in [0...Ur.PositionMax] by 1)
      addDangerOfTokenAt = (position, mult = 1) ->
        for i in [1..4] by 1
          destination = Math.min(position + i, Ur.PositionMax - 1)
          risk = [ 4, 6, 4, 1 ][i - 1] / 16
          if Ur.SpecialCellPositions.rethrow.indexOf(destination) >= 0
            addDangerOfTokenAt(destination, risk) # unless (list.indexOf(destination) >= 0) || (list_theirs.indexOf(destination) >= 0)
          continue unless Ur.PositionDisputeStart <= destination <= Ur.PositionDisputeEnd
          result[destination] += risk * mult
        null
      addDangerOfTokenAt(0) if @["#{our_side}_remaining"] > 0
      addDangerOfTokenAt(token) for token in list
      result[safe] = 0 for safe in Ur.SpecialCellPositions.safe# when @["#{their_side}_indices"].indexOf(safe) == -1
      result
    ###
    Qualify a potential move and return object with properties:

    - `move`: Cell index of evaluated move
    - `destination`: Cell index of where the token would end
    - `was_danger`: If position before move was in conflict cells
    - `was_rethrow`: If position before move was a rethrow cell
    - `rethrow`: If destination is a rethrow cell
    - `safe`: If destination is the safe cell
    - `danger`: If destination is in the conflict cells
    - `capture`: If not undefined, index (in the state array) of enemy token that would be captured
    - `wastes`: Number of potential moves not taken because the token would end past the final cell

    @param [number] move Cell index of move to qualify (if valid)
    @return [object]
    ###
    evaluateMove: (move) ->
      [ our_side, their_side ] = @getSideNames()
      result = { move }
      result.was_danger = true if (Ur.PositionDisputeStart <= move <= Ur.PositionDisputeEnd) && Ur.SpecialCellPositions.safe.indexOf(move) < 0
      result.was_rethrow = true if Ur.SpecialCellPositions.rethrow.indexOf(move) >= 0
      count = @getDiceValue()
      error = @isMoveIllegal move, (destination, piece_index, enemy_piece_index) =>
        result.destination = destination
        result.capture = enemy_piece_index if enemy_piece_index != -1
        result.wastes = count - delta if (delta = destination - move) < count
        result[k] = true for k, v of Ur.SpecialCellPositions when v.indexOf(destination) >= 0
        result.danger = true if (Ur.PositionDisputeStart <= destination <= Ur.PositionDisputeEnd) && !result.safe
      throw new Error(error) if error
      result
    ###
    Throw random dice to match a desired value, unless dice are set, then throw
    ###
    throwDiceCheating: (hardCodeValue) ->
      throw new Error("Dice ready") if @dice?
      @dice = Ur.getRandomDice() while (!@dice?) || (hardCodeValue? && Ur.getDiceValue(@dice) != hardCodeValue)
      @
    ###
    Throw random dice, unless dice are set, then throw
    ###
    throwDice: () ->
      # throw new Error("Error: Player's turn ready") if @turn != 0
      throw new Error("Dice ready") if @dice?
      @dice = Ur.getRandomDice()
      @
    ###
    Check that move at cell `p` is valid for the current player.
    @param [function(destination, piece_index, enemy_piece_index)] fn callback with calculated data
    @return [null|string] If move is valid, null, otherwise string describing the error
    ###
    isMoveIllegal: (p, fn) ->
      return "No player's turn" if @turn == 0
      return "Dice not ready" unless @dice?
      return "Invalid move start" unless 0 <= p < Ur.PositionMax - 1
      [ our_side, their_side ] = @getSideNames()
      count = @getDiceValue()
      enemy_piece_index = -1
      destination = Math.min(p + count, 15)
      if p == 0
        return "No remaining tokens" if @["#{our_side}_remaining"] < 1
      else
        piece_index = @["#{our_side}_indices"].indexOf(p)
        return "No token on #{p}" if piece_index < 0
      if destination < 15
        return "Piece already at destination" if @["#{our_side}_indices"].indexOf(destination) >= 0
        if Ur.PositionDisputeStart <= destination <= Ur.PositionDisputeEnd
          enemy_piece_index = @["#{their_side}_indices"].indexOf(destination)
          return "Safe destination occupied" if (enemy_piece_index >= 0) && Ur.SpecialCellPositions.safe.indexOf(destination) >= 0
      fn?(destination, piece_index, enemy_piece_index)
      null
    ###
    @return [undefined|number] if game is won, -1 or 1 for winning side, undefined otherwise
    ###
    haveWinner: ->
      return side for side in [-1, 1] when @countTokensSafe(side) == Ur.TokenCount
    ###
    @return [Array] Array of possible moves for current turn
    ###
    getAvailableMoves: ->
      throw new Error("No player's turn") if @turn == 0
      throw new Error("Dice not ready") unless @dice?
      [ our_side, their_side ] = @getSideNames()
      count = @getDiceValue()
      return [] if count == 0
      result = if @["#{our_side}_remaining"] > 0 then [ 0 ] else [ ]
      result = result.concat(@["#{our_side}_indices"])
      result = result.filter (p) => @isMoveIllegal(p) == null
      result
    ###
    Play given move and update game state accordingly. Throws if the move isn't valid.
    @param [number] p Cell number to play, -1 to pass
    ###
    playMove: (p) ->
      [ our_side, their_side ] = @getSideNames()
      result = null
      count = @getDiceValue()
      if p == -1
        if @getAvailableMoves().length == 0
          @dice = null
          @turn = if @turn < 0 then 1 else -1
          @["#{our_side}_stats"]?.didPlayTurn(true, count, p)
          @["#{their_side}_stats"]?.didPlayTurn(false, count, p)
          return true
        throw new Error("Invalid pass, moves possible")
      error = @isMoveIllegal p, (destination, piece_index, enemy_piece_index) =>
        @["#{our_side}_stats"]?.didPlayTurn(true, count, p, destination, enemy_piece_index >= 0)
        @["#{their_side}_stats"]?.didPlayTurn(false, count, p, destination, enemy_piece_index >= 0)

        if p == 0
          @["#{our_side}_remaining"] -= 1
        else
          @["#{our_side}_indices"].splice(piece_index, 1)
        if enemy_piece_index >= 0
          @["#{their_side}_remaining"] += 1
          @["#{their_side}_indices"].splice(enemy_piece_index, 1)
        @["#{our_side}_indices"].push(destination) unless destination == Ur.PositionMax - 1
        @ensureSorted()
        @dice = null
        if Ur.SpecialCellPositions.rethrow.indexOf(destination) >= 0
          @["#{our_side}_stats"]?.didRethrow()
          result = 'rethrow'
        else if destination == 15 && @countTokensLeft(@turn) == 0
          @turn = 0
          result = "#{our_side}_won"
        else
          @turn = if @turn < 0 then 1 else -1
          result = true
      throw new Error(error) if error
      result

    ###
    Serialised array format is:

        [
          0: turn (-1 = left, 1 = right)
          1: [ 4x dice values ]
          2: [ left_remaining,  left_indices... ]
          3: [ right_remaining, right_indices... ]
          4: [ left_stats, right_stats ]?
        ]

    @param [Array] data Load game state from JSON friendly array state
    ###
    loadFromArray: (data) ->
      [ @turn, @dice, [ @left_remaining, @left_indices... ], [ @right_remaining, @right_indices... ], [ @left_captures, @right_captures ], stats ] = data
      if stats?
        [ left_stats, right_stats ] = stats
        @left_stats .loadFromArray(left_stats)  if left_stats?
        @right_stats.loadFromArray(right_stats) if right_stats?
    ###
    Serialise game state int JSON friendly format, see `loadFromArray`
    ###
    writeToArray:         ->
      stats = [ @left_stats, @right_stats ].map (s) -> s?.writeToArray()
      stats = undefined unless stats[0] || stats[1]
      [ @turn, @dice, [ @left_remaining, @left_indices... ], [ @right_remaining, @right_indices... ], [ @left_captures, @right_captures ], stats ]
    ###
    Calls `loadFromArray` but reverts to previous state in case of invalid argument
    ###
    safeLoadFromArray: (data) ->
      previous = @writeToArray() if @turn?
      @loadFromArray(data)
      try
        @validateGameState()
      catch e
        @loadFromArray(previous) if previous?
        @validateGameState()
        throw e

  Ur.AI =
    ###
      @param ai {function} An AI is a function in `Ur.AI` that takes the `Ur.Game` instance and
                           an array of numerically sorted possible moves. The function is not called
                           when there is no or only one move possible. The function should return
                           the cell number of the move to play.
      @param delay {Number} Milliseconds to wait before playing the move after decision.
    ###
    toController: (ai, delay) ->
      yourTurn: (controller, game) ->
        moves = game.getAvailableMoves()
        move = switch moves.length
          when 0
            -1
          when 1
            moves[0]
          else
            ai(game, moves)
        if delay
          setTimeout((-> controller.playMove(move)), delay)
          move
        else
          controller.playMove(move)

    random: (game, moves) -> moves[getRandomIntIncMinExcMax(0, moves.length)]

    rush: (game, moves) -> moves[moves.length - 1]

    middle: (game, moves) ->
      evals = moves.map (move) -> game.evaluateMove(move)
      evals.reverse()
      return move.move for move in evals when move.capture?
      return move.move for move in evals when move.safe
      return move.move for move in evals when move.was_danger
      return move.move for move in evals when !move.danger?
      return move.move for move in evals when move.rethrow
      evals[evals.length - 1].move

    hard: (game, moves) ->
      evals = moves.map (move) -> game.evaluateMove(move)
      dangerMap = game.getAttackRiskMap(if game.turn < 0 then 1 else -1)
      for move in evals
        move.danger = dangerMap[move.destination] if move.danger?
        move.was_danger = dangerMap[move.move] if move.was_danger?
        move.danger_delta = (move.danger ? 0) - (move.was_danger ? 0)

        move.heuristic = move.danger_delta
        move.heuristic -= 1.2 if move.capture
        move.heuristic -= 0.4 if move.rethrow
        move.heuristic -= 0.4 if move.safe # adds with rethrow
        move.heuristic -= 0.2 if move.was_rethrow
        move.heuristic += 1.2 if move.was_safe # disadvantage because at 0 risk
      evals.sort (a, b) -> a.heuristic - b.heuristic
      # console.log "Picking #{evals[0].danger_delta} of #{evals.map((e) -> e.danger_delta).join(", ")}"
      evals[0].move

  Ur