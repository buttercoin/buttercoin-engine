Amount = require('./amount')
DQ = require('deque')

module.exports = class Ratio
  @init: (ratio, numerator, denominator) ->
    ratio.numerator = numerator || Amount.zero
    ratio.denominator = denominator || Amount.one
    unless ratio.numerator instanceof Amount and ratio.denominator instanceof Amount
      throw new Error("Can only create Ratios from Amounts: #{numerator.constructor.name}, #{denominator.constructor.name}")

    if ratio.denominator.is_zero() then throw new Error('Denominator cannot be 0')

    # XXX - don't use .value?
    gcd = new Amount(ratio.numerator.value.gcd(ratio.denominator.value).toString())

    old = ratio.numerator
    ratio.numerator = ratio.numerator.divide(gcd)
    ratio.denominator = ratio.denominator.divide(gcd)
    ratio.whole = ratio.numerator.divide(ratio.denominator) #.multiply(ratio.denominator)
    ratio.fraction = ratio.numerator.mod(ratio.denominator)

    return ratio

  constructor: (numerator, denominator) ->
    Ratio.init(this, numerator, denominator)

  compareTo: (other) =>
    # TODO - better coercion story
    other = new Ratio(other) if other instanceof Amount
    result = @whole.compareTo(other.whole)
    if result is 0
      if @denominator.eq(other.denominator) is 0
        result = @fraction.compareTo(other.fraction)
      else
        left = @fraction.multiply(other.denominator)
        right = other.fraction.multiply(@denominator)
        result = left.compareTo(right)

    return result

  eq: (other) =>
    # TODO - better coercion story
    if other instanceof Amount
      other = new Ratio(other)
    result = @numerator.eq(other.numerator) and @denominator.eq(other.denominator)
    return result

  inverse: =>
    new Ratio(@denominator.clone(), @numerator.clone())

  add: (other) =>
    if (other instanceof Amount)
      left = other.multiply(@denominator)
      numer = left.add(@numerator)

      result = new Ratio(
        left.add(@numerator),
        @denominator
      )
      return result
    else
      # TODO - assert Ratio instance?
      x = @numerator.multiply(other.denominator)
      y = other.numerator.multiply(@denominator)
      result = new Ratio(
        x.add(y),
        @denominator.multiply(other.denominator)
      )

      return result


  subtract: (other) =>
    if (other instanceof Amount)
      left = other.multiply(@denominator)
      result = new Ratio(
        @numerator.subtract(left),
        @denominator
      )
      return result
    else
      # TODO - assert Ratio instance?
      x = @numerator.multiply(other.denominator)
      y = other.numerator.multiply(@denominator)
      result = new Ratio(
        x.subtract(y),
        @denominator.multiply(other.denominator)
      )

      return result

  multiply: (other) =>
    if other instanceof Amount
      other = new Ratio(other)
    result = new Ratio(@numerator.multiply(other.numerator), @denominator.multiply(other.denominator))
    return result

  divide: (other) =>
    if other instanceof Amount
      other = new Ratio(other)
    result = new Ratio(@numerator.multiply(other.denominator), @denominator.multiply(other.numerator))
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
