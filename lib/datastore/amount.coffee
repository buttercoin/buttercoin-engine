#BigDecimal = require('bigdecimal').BigDecimal
BigRational = require('big-rational')

brToNumber = (x) ->
  x.num.valueOf() / x.denom.valueOf()

bdOne = new BigRational('1')

module.exports = class Amount
  constructor: (value) ->
    if typeof value == 'undefined'
      value = '0'

    if typeof value == 'string'
      try
        @value = new BigRational(value)
      catch e
        throw new Error('String initializer cannot be parsed to a number')
    else
      throw new Error('Must intialize from string')

  compareTo: (amount) =>
    if amount instanceof Amount
      return @value.compare(amount.value)
    else
      throw new Error('Can only compare to Amount objects')

  lte: (amount) => @compareTo(amount) <= 0
  gt: (amount) => @compareTo(amount) > 0
  eq: (amount) => @compareTo(amount) == 0
  is_zero: => @eq(Amount.zero)

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

  divide: (amount) =>
    if amount instanceof Amount
      result = new Amount()
      result.value = @value.divide(amount.value)
      return result
    else
      throw new Error('Can only divide Amount objects')

  multiply: (amount) =>
    if amount instanceof Amount
      result = new Amount()
      result.value = @value.multiply(amount.value)
      return result
    else
      throw new Error('Can only divide Amount objects')

  toString: =>
    return brToNumber(@value).toString()

  clone: =>
    return @add(new Amount())

  inverse: =>
    result = new Amount()
    result.value = bdOne.divide(@value)
    return result

Amount.zero = new Amount('0')
