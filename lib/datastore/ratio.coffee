Amount = require('./amount')

module.exports = class Price
  constructor: (@offered, @received) ->
    @offered ||= Amount.zero
    @received ||= Amount.one
    unless @offered instanceof Amount and @received instanceof Amount
      throw new Error('Can only create prices from Amounts')

    if @received.is_zero() then throw new Error('Denominator cannot be 0')

    # XXX - don't use .value?
    gcd = new Amount(@offered.value.gcd(@received.value).toString())
    @offered = @offered.divide(gcd)
    @received = @received.divide(gcd)
    @whole = @offered.divide(@received).multiply(@received)
    @fraction = @offered.mod(@received)

  compareTo: (other) =>
    result = @whole.compareTo(other.whole)
    if result is 0
      if @received.eq(other.received) is 0
        result = @fraction.compareTo(other.fraction)
      else
        left = @fraction.multiply(other.received)
        right = other.fraction.multiply(@received)
        result = left.compareTo(right)
    return result

  eq: (other) =>
    @offered.eq(other.offered) and @received.eq(other.received)

  inverse: =>
    new Price(@received.clone(), @offered.clone())

  multiply: (other) =>
    other = new Price(other) if other instanceof Amount
    new Price(@received.multiply(other.received), @offered.multiply(other.offered))

  toString: =>
    "#{@offered}/#{@received}"
