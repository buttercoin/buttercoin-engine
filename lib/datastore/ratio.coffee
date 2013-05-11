Amount = require('./amount')

module.exports = class Ratio
  constructor: (@numerator, @denominator) ->
    @numerator ||= Amount.zero
    @denominator ||= Amount.one
    unless @numerator instanceof Amount and @denominator instanceof Amount
      throw new Error('Can only create prices from Amounts')

    if @denominator.is_zero() then throw new Error('Denominator cannot be 0')

    # XXX - don't use .value?
    gcd = Amount.take(@numerator.value.gcd(@denominator.value).toString())
    @numerator = @numerator.divide(gcd)
    @denominator = @denominator.divide(gcd)
    @whole = @numerator.divide(@denominator) #.multiply(@denominator)
    @fraction = @numerator.mod(@denominator)

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
    other = new Ratio(other) if other instanceof Amount
    @numerator.eq(other.numerator) and @denominator.eq(other.denominator)

  inverse: =>
    new Ratio(@denominator.clone(), @numerator.clone())

  add: (other) =>
    if (other instanceof Amount)
      return new Ratio(
        other.multiply(@denominator).add(@numerator),
        @denominator
      )
    else
      # TODO - assert Ratio instance?
      return new Ratio(
        @numerator.multiply(other.denominator).add(
          other.numerator.multiply(@denominator)),
        @denominator.multiply(other.denominator)
      )

  subtract: (other) =>
    if (other instanceof Amount)
      return new Ratio(
        @numerator.subtract(other.multiply(@denominator)),
        @denominator
      )
    else
      # TODO - assert Ratio instance?
      return new Ratio(
        @numerator.multiply(other.denominator).subtract(
          other.numerator.multiply(@denominator)),
        @denominator.multiply(other.denominator)
      )

  multiply: (other) =>
    other = new Ratio(other) if other instanceof Amount
    new Ratio(@numerator.multiply(other.numerator), @denominator.multiply(other.denominator))

  divide: (other) =>
    new Ratio(@numerator.multiply(other.denominator), @denominator.multiply(other.numerator))

  toString: =>
    "#{@numerator}/#{@denominator}"

  @precisionFactor: new Amount('100000000')
  toAmount: =>
    return @multiply(Ratio.precisionFactor).whole.divide(Ratio.precisionFactor)

  is_zero: =>
    return @numerator.is_zero()
