define [
], (
) ->
  getRandomIntIncMinExcMax = (min, max) -> Math.floor(Math.random() * (max - min)) + min
  Ur = 
    PositionDisputeStart: 5
    PositionDisputeEnd: 12
    PositionMax: 16
    DiceCount: 4
    DicePositions: 6
    SpecialCellPositions:
      rethrow: [4, 8, 14]
      safe: [8]
    TokenCount: 7
    getRandomDice: -> getRandomIntIncMinExcMax(0, @DicePositions) for i in [0...@DiceCount]
    getDiceValue: (dice) ->
      total = 0
      total += 1 for i in [0...@DiceCount] when (dice[i] & 1) == 1
      total

    checkPositionIndex: (p) -> throw new Error("Invalid move #{JSON.stringify(p)}") unless 0 <= p < @PositionMax
    #   |   0   1    2
    # --+--------------
    # 0 |  d4   5   d4
    # 1 |   3   6    3
    # 2 |   2   7    2
    # 3 |   1  x8    1
    # 4 |(s 0)  9 (s 0)
    # 5 |(e15) 10 (e15)
    # 6 | d14  11  d14
    # 7 |  13  12   13
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
    getCellProperties: (x, y) ->
      [p, is_left] = @getPositionFromXY(x, y)
      result = if p == 0 then { starter: true } else (if p == @PositionMax - 1 then { ender: true } else { cell: true} )
      result[prop] = true for prop in ['safe', 'rethrow'] when @SpecialCellPositions[prop].indexOf(p) >= 0
      result
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
  Ur.GameController = class UrGameController
    constructor: (@game, @listener, @leftPlayerController, @rightPlayerController) ->
      @reset()
    getPlayerController: (turn = @game.turn) -> if turn == -1 then @leftPlayerController else (if turn == 1 then @rightPlayerController)
    __onNewTurn: (skipThrowDice) ->
      if (turn = @game.turn)
        controller = @getPlayerController(turn)
        @game.throwDice() unless skipThrowDice
        if controller?
          controller.yourTurn(@, @game)
      @listener.onGameChange(@game, controller)
    abort: -> @aborted = true
    playMove: (move) ->
      throw new Error("Game aborted") if @aborted
      @game.playMove(move)
      @__onNewTurn()
    reset: (skipThrowDice) ->
      delete @aborted
      @game.reset()
      @game.turn = (getRandomIntIncMinExcMax(0, 2) && 1) || -1
      @__onNewTurn()
      
  Ur.Game = class UrGame
    @ExampleStates:
      stuckByPositions: [ -1, [ 0, 1, 2, 3 ], [ 1, 2, 4, 6 ], [ 0, 8 ], [ 0, 0 ] ]
      stuckByDice:      [  1, [ 0, 2, 4, 0 ], [ 6, 2 ],       [ 5, 4 ], [ 0, 0 ] ]
    constructor: (state) -> if state? then @safeLoadFromArray(state) else @reset()
    reset: -> @safeLoadFromArray([0, null, [ Ur.TokenCount ], [ Ur.TokenCount ], [ 0, 0 ]])
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
    getSideName: (side) ->
      if typeof side is 'number' then (if side == -1 then 'left' else if side == 1 then 'right') else side
    getSideNames: (side) ->
      throw new Error("Invalid side #{side}") unless side in [-1, 1]
      [ @getSideName(side), @getSideName(if side == -1 then 1 else -1) ]
    countCaptures: (side) ->
      @["#{@getSideName(side)}_captures"]
    countTokensLeft: (side) ->
      side = @getSideName(side)
      @["#{side}_remaining"] + @["#{side}_indices"].length
    countTokensSafe: (side) -> Ur.TokenCount - @countTokensLeft(side)
    ensureSorted: ->
      @left_indices.sort((a, b) -> b - a)
      @right_indices.sort((a, b) -> b - a)
      @
    findFurthestPiece: (side) ->
      side = @getSideName(side)
      @ensureSorted()
      list = @["#{side}_indices"]
      if list.length > 0 then list[list.length - 1] else (if @["#{side}_remaining"] > 0 then 0 else -1)
    getDiceValue: -> Ur.getDiceValue(@dice)

    throwDiceCheating: (hardCodeValue) ->
      throw new Error("Dice ready") if @dice?
      @dice = Ur.getRandomDice() while (!@dice?) || (hardCodeValue? && Ur.getDiceValue(@dice) != hardCodeValue)
      @
    throwDice: () ->
      # throw new Error("Error: Player's turn ready") if @turn != 0
      throw new Error("Dice ready") if @dice?
      @dice = Ur.getRandomDice()
      @
    isMoveIllegal: (p, fn) ->
      return "No player's turn" if @turn == 0
      return "Dice not ready" unless @dice?
      return "Invalid move start" unless 0 <= p < Ur.PositionMax - 1
      [ our_side, their_side ] = @getSideNames(@turn)
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
    haveWinner: ->
      return side for side in [-1, 1] when @countTokensSafe(side) == Ur.TokenCount
    getAvailableMoves: ->
      throw new Error("No player's turn") if @turn == 0
      throw new Error("Dice not ready") unless @dice?
      [ our_side, their_side ] = @getSideNames(@turn)
      count = @getDiceValue()
      return [] if count == 0
      result = if @["#{our_side}_remaining"] > 0 then [ 0 ] else [ ]
      result = result.concat(@["#{our_side}_indices"])
      result = result.filter (p) => @isMoveIllegal(p) == null
      result
    playMove: (p) ->
      result = null
      if p == -1
        if @getAvailableMoves().length == 0
          @dice = null
          @turn = if @turn < 0 then 1 else -1
          return true
        throw new Error("Invalid pass, moves possible")
      error = @isMoveIllegal p, (destination, piece_index, enemy_piece_index) =>
        [ our_side, their_side ] = @getSideNames(@turn)
        if p == 0
          @["#{our_side}_remaining"] -= 1
        else
          @["#{our_side}_indices"].splice(piece_index, 1)
        if enemy_piece_index >= 0
          @["#{our_side}_captures"] += 1
          @["#{their_side}_remaining"] += 1
          @["#{their_side}_indices"].splice(enemy_piece_index, 1)
        @["#{our_side}_indices"].push(destination) unless destination == Ur.PositionMax - 1
        @ensureSorted()
        @dice = null
        if Ur.SpecialCellPositions.rethrow.indexOf(destination) >= 0
          result = 'rethrow'
        else if destination == 15 && @countTokensLeft(@turn) == 0
          @turn = 0
          result = "#{our_side}_won"
        else
          @turn = if @turn < 0 then 1 else -1
          result = true
      throw new Error(error) if error
      result


    # [
    #   0: turn (1 = right)
    #   1: [ 4x dice values ]
    #   2: [ left_remaining,  left_indices... ]
    #   3: [ right_remaining, right_indices... ]
    # ]
    loadFromArray: (data) -> [ @turn, @dice, [ @left_remaining, @left_indices... ], [ @right_remaining, @right_indices... ], [ @left_captures, @right_captures ] ] = data
    writeToArray:         -> [ @turn, @dice, [ @left_remaining, @left_indices... ], [ @right_remaining, @right_indices... ], [ @left_captures, @right_captures ] ]
    safeLoadFromArray: (data) ->
      previous = @writeToArray() if @turn?
      @loadFromArray(data)
      try
        @validateGameState()
      catch e
        @loadFromArray(previous) if previous?
        @validateGameState()
        throw e


  Ur