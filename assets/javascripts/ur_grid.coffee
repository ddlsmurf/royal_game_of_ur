define [
  'jquery'
  'templates'
  './ur'
], (
  $
  templates
  Ur
) ->

  UrCellClasses =
    hasLeft: 'has_blue'
    hasRight: 'has_red'
    flashing: 'flashing'
    available: 'available'
  makeSVGBackgroundImageURL = do ->
    f = (svgAttributes, svgText) ->
      svgSizing = "width='100%' height='100%' viewBox='0 0 #{width} #{height}' preserveAspectRatio='none'"
      svg = [ "<svg xmlns='http://www.w3.org/2000/svg' ", svgSizing, " #{svgAttributes}>", svgText, "</svg>" ]
      'url("data:image/svg+xml;utf8,' + encodeURIComponent(svg.join("")) + '")'
    f.midX = f.midY = (f.width = f.height = width = height = 10) / 2
    f.getXOfEdge = (edge) -> if edge == 'l' then 0 else (if edge == 'r' then width else width / 2)
    f.getYOfEdge = (edge) -> if edge == 't' then 0 else (if edge == 'b' then height else height / 2)
    f

  makeSVGBackgroundImageLine = (color, entry, exit) ->
    svgStyling = "stroke-width='1' stroke='#{color}' stroke-linejoin='round' fill='none'"
    result = ["<path d='"]
    result.push "M#{makeSVGBackgroundImageURL.getXOfEdge(entry)},#{makeSVGBackgroundImageURL.getYOfEdge(entry)}"
    result.push " L#{makeSVGBackgroundImageURL.midX},#{makeSVGBackgroundImageURL.midY}"
    result.push " L#{makeSVGBackgroundImageURL.getXOfEdge(exit)},#{makeSVGBackgroundImageURL.getYOfEdge(exit)}" if exit
    result.push "' />"
    return makeSVGBackgroundImageURL(svgStyling, result.join(""))

    width = height = 10
    getXOfEdge = (edge) -> if edge == 'l' then 0 else (if edge == 'r' then width else width / 2)
    getYOfEdge = (edge) -> if edge == 't' then 0 else (if edge == 'b' then height else height / 2)
    result = []
    svgSizing = "width='100%' height='100%' viewBox='0 0 #{width} #{height}' preserveAspectRatio='none'"
    svgStyling = "stroke-width='1' stroke='#{color}' stroke-linejoin='round' fill='none'"
    result.push "<svg xmlns='http://www.w3.org/2000/svg' #{svgSizing} #{svgStyling}>"
    result.push "<path d='"
    result.push "M#{getXOfEdge(entry)},#{getYOfEdge(entry)}"
    result.push " L#{width / 2},#{height / 2}"
    result.push " L#{getXOfEdge(exit)},#{getYOfEdge(exit)}" if exit
    result.push "' />"
    result.push "</svg>"
    'url("data:image/svg+xml;utf8,' + encodeURIComponent(result.join("")) + '")'
    # background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='10' stroke-width='3' stroke='white'><polygon points='0,0 10,10' /></svg>")

  class UrGrid
    constructor: (@listener) ->
      @$el = $(templates['ur_grid']({Ur}))
      @clearCellTokens()
      grid = @
      @$el.delegate 'td', 'click', ->
        $cell = $(@)
        [x, y] = (parseInt($cell.attr("data-#{a}")) for a in ['x', 'y'])
        grid.listener.onMove(Ur.getPositionFromXY(x, y)...)
      @
    getCells: -> @$el.find("td")
    getCell: (x, y) -> @$el.find("td[data-x='#{x}'][data-y='#{y}']")
    clearPath: -> @getCells().css(backgroundImage: '')
    showPath: (start, count, is_left) ->
      throw new Error("Invalid start #{start}") if start < 0
      count = Ur.PositionMax - start - 1 if (start + count) >= Ur.PositionMax
      movementFlip = (movement) -> ({l: 'r', r: 'l', t: 'b', b: 't'})[movement] ? movement
      color = Ur.Colors[if is_left then 'left' else 'right']
      @clearPath()
      xyPrev = Ur.getXYFromPosition(start, is_left)
      previousExit = null
      while count > 0
        count -= 1
        start += 1
        xyNext = Ur.getXYFromPosition(start, is_left)
        movement = if xyNext[0] > xyPrev[0] then "r" else (if xyNext[0] < xyPrev[0] then "l" else (if xyNext[1] > xyPrev[1] then "b" else "t"))
        @getCell(xyPrev[0], xyPrev[1]).css(backgroundImage: makeSVGBackgroundImageLine(color, previousExit, movement))
        previousExit = movementFlip(movement)
        xyPrev = xyNext
      @getCell(xyPrev[0], xyPrev[1]).css(backgroundImage: makeSVGBackgroundImageLine(color, previousExit, null))
      @
    clearFlashingCells: -> @getCells().removeClass(UrCellClasses.flashing)
    clearAvailableMoveCells: -> @getCells().removeClass(UrCellClasses.available)
    showAvailableMoveCells: (moves, turn) ->
      moves.forEach (pos) =>
        [x, y] = Ur.getXYFromPosition(pos, turn == -1)
        @getCell(x, y).addClass(UrCellClasses.available)
    flashSpecialCells: (kind) ->
      @clearFlashingCells()
      @$el.find("td.#{kind}").addClass(UrCellClasses.flashing) if kind?
    clearCellTokens: -> @getCells().removeClass(UrCellClasses.hasLeft + " " + UrCellClasses.hasRight).find('.token').text('')
    addCellToken: (p, is_left, count = 1) ->
      [x, y] = Ur.getXYFromPosition(p, is_left)
      @getCell(x, y).toggleClass(UrCellClasses.hasLeft, (count > 0) && is_left).toggleClass(UrCellClasses.hasRight, (count > 0) && (!is_left)).find('.token').text(if count > 1 then count else '')
    updateFromGame: (game) ->
      @clearAvailableMoveCells()
      @clearCellTokens()
      @addCellToken(0, true, game.left_remaining)
      @addCellToken(0, false, game.right_remaining)
      @addCellToken(p, true, 1) for p in game.left_indices
      @addCellToken(p, false, 1) for p in game.right_indices
      @addCellToken(15, true, game.countTokensSafe('left'))
      @addCellToken(15, false, game.countTokensSafe('right'))
      # try
      #   game.getAvailableMoves().forEach (pos) =>
      #     [x, y] = Ur.getXYFromPosition(pos, game.turn == -1)
      #     @getCell(x, y).addClass(UrCellClasses.available)
      # catch e
        # nada
      @