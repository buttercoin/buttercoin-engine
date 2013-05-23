Market = require('./market')

module.exports = class SuperMarket
  constructor: ->
    @markets = Object.create null

  get_market: (offered_currency, received_currency) =>

    if offered_currency == received_currency
      throw Error("#{offered_currency}|#{received_currency} is not a valid market")

    if offered_currency < received_currency
      canonical_pair =  [offered_currency, received_currency]
    else
      canonical_pair = [received_currency, offered_currency]

    canonical_pair_string = canonical_pair.join('|') # XXX: no | in name

    market = @markets[canonical_pair_string]
    if not (market instanceof Market)
      @markets[canonical_pair_string] = market = new Market( canonical_pair[0], canonical_pair[1] )
    return market

  route_order: (order) =>
    @get_market('USD', 'BTC').add_order(order)

  create_snapshot: =>
    result = {}
    for k, v of @markets
      result[k] = v.create_snapshot()
    return result

  @load_snapshot: (data) =>
    sm = new SuperMarket()
    for k, v of data
      sm.markets[k] = Market.load_snapshot(v)
    return sm

