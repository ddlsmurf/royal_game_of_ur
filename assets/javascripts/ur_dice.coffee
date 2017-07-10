define [
  'jquery'
  'templates'
  './ur'
], (
  $
  templates
  Ur
) ->
  class UrDice
    constructor: ->
      @$el = $(templates['ur_dice']({Ur}))
      @$dice = @$el.find('.dice').map(-> $(@))
    getDice: (i) ->
      throw new Error("Invalid dice ##{i}") unless 0 <= i < Ur.DiceCount
      @$dice[i]
    randomizeDice: -> @setDice(Ur.getRandomDice())
    setSingleDice: (i, value) ->
      throw new Error("Invalid dice value ##{value}") unless 0 <= value < Ur.DicePositions
      @getDice(i).attr('data-value', value)
      value & 1
    setTotal: (label) -> @$el.find(".total").text(label)
    setDice: (values) ->
      if values? && typeof values != 'string'
        throw new Error("Invalid length #{JSON.stringify(values)}") unless values.length == Ur.DiceCount
        @setSingleDice(i, values[i]) for i in [0...Ur.DiceCount]
        @setTotal(Ur.getDiceValue(values))
        @$el.addClass('have_value')
      else
        @$el.find('.not_your_turn').text(if typeof values is 'string' then values else '')
        @$el.removeClass('have_value')