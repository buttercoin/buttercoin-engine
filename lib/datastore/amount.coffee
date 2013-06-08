bignum = require('bignum')
DQ = require('deque')

module.exports = class Amount
  flyweight_pool = new DQ.Dequeue()
  @flyweight_pool = flyweight_pool
  @num_allocated = 0
  @num_took = 0
  @num_put = 0

  @take: (value) =>
    if @flyweight_pool.length is 0 #isEmpty()
      return new Amount(value)
    else
      @num_took += 1
      x = @flyweight_pool.pop()
      @init(x, value)

  @put: (amount) =>
    #throw new Error("Invalid Amount: #{amount}") unless amount instanceof Amount
    @num_put += 1
    @flyweight_pool.push(amount)

  @init: (amount, value) =>
    Amount.num_allocated += 1
    if typeof value == 'undefined'
      value = '0'

    if typeof value == 'string'
      if isNaN(value)
        throw new Error('String initializer cannot be parsed to a number')
      try
        amount.value = new bignum(value)
      catch e
        throw new Error('String initializer cannot be parsed to a number')
    else
      throw new Error('Must intialize from string')

    return amount

  constructor: (value) ->
    Amount.init(this, value)

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

  create_snapshot: =>
    @toString()

  @load_snapshot: (data) =>
    Amount.take(data)

Amount.zero = new Amount('0')
Amount.one = new Amount('1')
