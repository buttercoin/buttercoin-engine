#BigDecimal = require('bigdecimal').BigDecimal
BigRational = require('big-rational')

brToNumber = (x) ->
  x.num.valueOf() / x.denom.valueOf()

bdOne = new BigRational('1')

module.exports = class Amount
  constructor: (string_value) ->
    if typeof string_value == 'undefined'
      string_value = '0'

    if typeof string_value == 'string'
      try
        @value = new BigRational(string_value)
      catch e
        throw new Error('String initializer cannot be parsed to a number')
    else
      throw new Error('Must intialize from string')

  compareTo: (amount) =>
    if amount instanceof Amount
      return @value.compare(amount.value)
    else
      throw new Error('Can only compare to Amount objects')

  add: (amount) =>
    if amount instanceof Amount
      sum = new Amount()
      sum.value = @value.add(amount.value)
      return sum
    else
      throw new Error('Can only add Amount objects')

  subtract: (amount) =>
    if amount instanceof Amount
      difference = new Amount()
      difference.value = @value.subtract(amount.value)
      return difference
    else
      throw new Error('Can only subtract Amount objects')

  toString: =>
    return brToNumber(@value).toString()

  clone: =>
    return @add(new Amount())

  inverse: =>
    result = new Amount()
    result.value = bdOne.divide(@value)
    return result
