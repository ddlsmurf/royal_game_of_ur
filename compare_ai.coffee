withGlobal = (name, value, fn) ->
  prev = global[name]
  global[name] = value
  try
    fn()
  finally
    global[name] = prev

requireAMD = (path) ->
  defineCalled = false
  result = undefined
  define = (deps, fn) ->
    throw new Error("Error loading #{path}: dependencies not supported") if deps?.length > 0
    throw new Error("define called more than once") if defineCalled
    result = fn()
    defineCalled = true
  withGlobal 'define', define, -> require(path)
  throw new Error("Error loading #{path}, define() was not called") unless defineCalled
  result

Ur = requireAMD('./assets/javascripts/ur')

play = (ai1, ai2) ->
  game_listener = onGameChange: (game, playerController, expectedMove) ->
  controller = new Ur.GameController(game_listener,
    Ur.AI.toController(ai1),
    Ur.AI.toController(ai2))
  controller.game

playRepeatedly = (count, ai1, ai2) ->
  stats = [[], []]
  victories = [0, 0]
  for i in [0...count] by 1
    game = play(ai1, ai2)
    stats[0].push game.left_stats
    stats[1].push game.right_stats
    winner = game.haveWinner()
    throw new Error("Game not won ! #{JSON.stringify(game, null, 2)}") unless winner?
    victories[if winner == -1 then 0 else 1] += 1
  [victories, stats]

getKey = (obj, key) ->
  r = obj[key]
  if typeof(r) == 'function' then r.apply(obj) else r
countBoolKeys = (list, key) -> list.reduce(((sum, obj) -> sum + (if getKey(obj, key) then 1 else 0)), 0)
percentBoolKeys = (list, key) -> (countBoolKeys(list, key) * 100) / list.length
percentBoolKeys.suffix = "%"
sumKeys = (list, key) -> list.reduce(((sum, obj) -> sum + (getKey(obj, key) ? 0)), 0)
averageKeys = (list, key) -> sumKeys(list, key) / list.length
toRoundPercent = (ratio) -> Math.round(ratio * 100) + "%"
repeatStr = (count, str = " ") -> (new Array(count + 1)).join(str)
wrap = (l, width, str) ->
  rem = Math.max(0, width - str.length)
  if rem == 0 then str else (if l then str + repeatStr(rem) else repeatStr(rem) + str)
mapAll = (list, fn) -> # Normal Array::map doesn't include unassigned
  result = new Array(list.length)
  result[i] = fn(val, i) for val, i in list
  result

logStat = (count, ai1Name, ai2Name, method, key, [stats1, stats2]) ->
  ai1Result = "#{Math.round(method(stats1, key))}#{method.suffix ? ""}"
  ai2Result = "#{Math.round(method(stats2, key))}#{method.suffix ? ""}"
  # console.log "#{key}: \t#{ai1Name} #{ai1Result}\t#{ai2Name} #{ai2Result}"
  [key, ai1Result, ai2Result]
ralign = (str, len) ->
  width = len - str.length
  if width <= 0 then str else ((new Array(width + 1)).join(" ") + str)
alignTable = (rows) ->
  rows = mapAll rows, (r) -> mapAll r, (c) -> if c? then "" + c else ""
  widths = []
  rows.forEach (row) -> row.forEach (cell, col) ->
    widths[col] = Math.max((widths[col] ? 0), cell.length)
  rows.map (row) -> row.map (cell, col) ->
    if (width = widths[col] ? 0) then ralign(cell, width) else cell
printTableAligned = (table) -> alignTable(table).forEach (row, i) -> console.log row.join(" | ")
compareAIs = (count, ai1Name, ai2Name) ->
  [ ai1, ai2 ] = [ Ur.AI[ai1Name], Ur.AI[ai2Name] ]
  [ victories, stats ] = playRepeatedly(count, ai1, ai2)
  # console.log stats[0][0]
  [
    [ "", ai1Name, ai2Name ]
    [ "% won", toRoundPercent(victories[0] / count), toRoundPercent(victories[1] / count) ]
    [ "victories", victories... ]
    logStat count, ai1Name, ai2Name, percentBoolKeys, 'was_first',             stats
    logStat count, ai1Name, ai2Name, averageKeys,     'wasted',                stats
    logStat count, ai1Name, ai2Name, averageKeys,     'rethrows',              stats
    logStat count, ai1Name, ai2Name, averageKeys,     'blocks',                stats
    logStat count, ai1Name, ai2Name, averageKeys,     'captures',              stats
    logStat count, ai1Name, ai2Name, averageKeys,     'getTotalThrows',        stats
    logStat count, ai1Name, ai2Name, averageKeys,     'getThrowCount',         stats
    logStat count, ai1Name, ai2Name, averageKeys,     'getBlockedWithoutDice', stats
  ]
# table = compareAIs(300, 'hard', 'rush')
# printTableAligned(table)
compareAIMatrix = (count, includingSelves, aiNames...) ->
  result = aiNames.map -> []
  for i in [0...aiNames.length - (if includingSelves then 0 else 1)] by 1
    for j in [i + (if includingSelves then 0 else 1)...aiNames.length] by 1
      console.log aiNames[i], " vs ", aiNames[j]
      [ victories ] = playRepeatedly(count, Ur.AI[aiNames[i]], Ur.AI[aiNames[j]])
      result[i][j] = toRoundPercent(victories[0] / count)
      if i != j
        result[j][i] = toRoundPercent(victories[1] / count)
  [ [ ",- vs ->", aiNames... ] ].concat result.map (row, i) -> [aiNames[i]].concat(row)

printTableAligned(compareAIMatrix(300, true, 'random', 'rush', 'middle', 'hard'))

