Amount = require('./amount')

module.exports = class Price
  constructor: (@offered, @received) ->
    unless @offered instanceof Amount and @received instanceof Amount
      throw new Error('Can only create prices from Amounts')

    if @offered.is_zero() then throw new Error('Cannot have a zero price')
    if @received.is_zero() then throw new Error('Denominator cannot be 0')

    # XXX - don't use .value?
    gcd = new Amount(@offered.value.gcd(@received.value).toString())
    @offered = @offered.divide(gcd)
    @received = @received.divide(gcd)

  eq: (other) =>
    @offered.eq(other.offered) and @received.eq(other.received)

  inverse: =>
    new Price(@received.clone(), @offered.clone())

  toString: =>
    "#{@offered}/#{@received}"
