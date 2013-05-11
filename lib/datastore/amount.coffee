#BigDecimal = require('bigdecimal').BigDecimal
#BigRational = require('big-rational')

#brToNumber = (x) ->
  #x.num.valueOf() / x.denom.valueOf()

#bdOne = new BigRational('1')

bignum = require('bignum')
DQ = require('deque')

flyweight_pool = new DQ.Dequeue()

module.exports = class Amount
  @take: (value) =>
    if flyweight_pool.isEmpty()
      return new Amount(value)
    else
      x = flyweight_pool.pop()
      x.value = new bignum(value) if value
      return x

  @put: (amount) =>
    flyweight_pool.push(amount)

  constructor: (value) ->
    if typeof value == 'undefined'
      value = '0'

    if typeof value == 'string'
      if isNaN(value)
        throw new Error('String initializer cannot be parsed to a number')
      try
        @value = new bignum(value)
      catch e
        throw new Error('String initializer cannot be parsed to a number')
    else
      throw new Error('Must intialize from string')

  compareTo: (amount) =>
    if amount instanceof Amount
      return @value.cmp(amount.value)
    else
      throw new Error('Can only compare to Amount objects')

  lte: (amount) => @value.le(amount)
  gt: (amount) => @value.gt(amount)
  eq: (amount) => @value.eq(amount)
  is_zero: => @eq(Amount.zero)

  add: (amount) =>
    if amount instanceof Amount
      sum = Amount.take()
      sum.value = @value.add(amount.value)
      return sum
    else
      throw new Error('Can only add Amount objects')

  subtract: (amount) =>
    if amount instanceof Amount
      difference = Amount.take()
      difference.value = @value.sub(amount.value)
      return difference
    else
      throw new Error('Can only subtract Amount objects')

  divide: (amount) =>
    if amount instanceof Amount
      result = Amount.take()
      result.value = @value.div(amount.value)
      return result
    else
      throw new Error('Can only divide Amount objects')

  multiply: (amount) =>
    if amount instanceof Amount
      result = Amount.take()
      result.value = @value.mul(amount.value)
      return result
    else
      throw new Error('Can only multiply Amount objects')

  mod: (amount) =>
    if amount instanceof Amount
      result = Amount.take()
      result.value = @value.mod(amount.value)
      return result
    else
      throw new Error('Can only divide Amount objects')

  toString: =>
    return @value.toString() #brToNumber(@value).toString()

  clone: =>
    result = Amount.take()
    result.value = @value
    return result

Amount.zero = new Amount('0')
Amount.one = new Amount('1')
