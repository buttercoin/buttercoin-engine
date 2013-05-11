Amount = require('./amount')
DQ = require('deque')

module.exports = class Ratio
  flyweight_pool = new DQ.Dequeue()
  @flyweight_pool = flyweight_pool
  @num_allocated = 0
  @num_took = 0
  @num_put = 0

  @take: (numerator, denominator) ->
    if flyweight_pool.isEmpty()
      return new Ratio(numerator, denominator)
    else
      @num_took += 1
      x = flyweight_pool.pop()
      Ratio.init(x, numerator, denominator)

  @put: (ratio) ->
    #throw new Error("Invalid Ratio: #{ratio}") unless ratio instanceof Ratio
    @num_put += 1
    flyweight_pool.push(ratio)

  @init: (ratio, numerator, denominator) ->
    ratio.numerator = numerator || Amount.zero
    ratio.denominator = denominator || Amount.one
    unless ratio.numerator instanceof Amount and ratio.denominator instanceof Amount
      throw new Error("Can only create Ratios from Amounts: #{numerator.constructor.name}, #{denominator.constructor.name}")

    if ratio.denominator.is_zero() then throw new Error('Denominator cannot be 0')

    # XXX - don't use .value?
    gcd = Amount.take(ratio.numerator.value.gcd(ratio.denominator.value).toString())

    old = ratio.numerator
    ratio.numerator = ratio.numerator.divide(gcd)
    ratio.denominator = ratio.denominator.divide(gcd)
    ratio.whole = ratio.numerator.divide(ratio.denominator) #.multiply(ratio.denominator)
    ratio.fraction = ratio.numerator.mod(ratio.denominator)

    Amount.put(gcd)
    return ratio

  constructor: (numerator, denominator) ->
    Ratio.num_allocated += 1
    Ratio.init(this, numerator, denominator)

  compareTo: (other) =>
    # TODO - better coercion story
    other = Ratio.take(other) if other instanceof Amount
    result = @whole.compareTo(other.whole)
    if result is 0
      if @denominator.eq(other.denominator) is 0
        result = @fraction.compareTo(other.fraction)
      else
        left = @fraction.multiply(other.denominator)
        right = other.fraction.multiply(@denominator)
        result = left.compareTo(right)
        Amount.put(left)
        Amount.put(right)

    return result

  eq: (other) =>
    # TODO - better coercion story
    if other instanceof Amount
      other = Ratio.take(other)
      cleanup = true
    result = @numerator.eq(other.numerator) and @denominator.eq(other.denominator)
    Ratio.put(other) if cleanup
    return result

  inverse: =>
    Ratio.take(@denominator.clone(), @numerator.clone())

  add: (other) =>
    if (other instanceof Amount)
      left = other.multiply(@denominator)
      numer = left.add(@numerator)

      result = Ratio.take(
        left.add(@numerator),
        @denominator
      )
      Amount.put(left)
      return result
    else
      # TODO - assert Ratio instance?
      x = @numerator.multiply(other.denominator)
      y = other.numerator.multiply(@denominator)
      result = Ratio.take(
        x.add(y),
        @denominator.multiply(other.denominator)
      )
      Amount.put(x)
      Amount.put(y)

      return result


  subtract: (other) =>
    if (other instanceof Amount)
      left = other.multiply(@denominator)
      result = Ratio.take(
        @numerator.subtract(left),
        @denominator
      )
      Amount.put(left)
      return result
    else
      # TODO - assert Ratio instance?
      x = @numerator.multiply(other.denominator)
      y = other.numerator.multiply(@denominator)
      result = Ratio.take(
        x.subtract(y),
        @denominator.multiply(other.denominator)
      )
      Amount.put(x)
      Amount.put(y)

      return result

  multiply: (other) =>
    if other instanceof Amount
      other = Ratio.take(other)
      cleanup = true
    result = Ratio.take(@numerator.multiply(other.numerator), @denominator.multiply(other.denominator))
    Ratio.put(other) if cleanup
    return result

  divide: (other) =>
    if other instanceof Amount
      other = Ratio.take(other)
      cleanup = true
    result = Ratio.take(@numerator.multiply(other.denominator), @denominator.multiply(other.numerator))
    Ratio.put(other) if cleanup
    return result

  toString: =>
    "#{@numerator}/#{@denominator}"

  @precisionFactor: new Amount('100000000')
  toAmount: =>
    x = @multiply(Ratio.precisionFactor)
    result = x.whole.divide(Ratio.precisionFactor)
    return result

  is_zero: =>
    return @numerator.is_zero()
