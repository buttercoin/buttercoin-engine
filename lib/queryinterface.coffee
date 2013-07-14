Account = require('./datastore/account')
op = require('./operations')

module.exports = class QueryInterface
  constructor: (@datastore) ->
    @balancesheet = @datastore.balancesheet
    @supermarket = @datastore.supermarket
    
  get_balances: (account_id) =>
    acct = @balancesheet.get_account(account_id)
    balances = {}
    for c, v of Account.supported_currencies
      balances[c] = acct.get_balance(c).toString() if v
    return op.create.result[op.BALANCES](account_id, balances)

  get_open_orders: (account_id) =>
    acct = @balancesheet.get_account(account_id)
    return op.create.result[op.OPEN_ORDERS](account_id, acct.get_open_orders())

  get_spread: (left_currency, right_currency) ->
    market = @supermarket.get_market(left_currency, right_currency)

    books = [market.left_book, market.right_book]
    prices = books.map (x) => @top_of_book(x).price

    if market.left_currency is left_currency
      prices[1] = prices[1]?.inverse()
    else
      prices[0] = prices[0]?.inverse()

    return {
      bid: prices[0]
      ask: prices[1] #.inverse()
    }

  get_ticker: (left_currency, right_currency) ->
    market = @supermarket.get_market(left_currency, right_currency)
    spread = @get_spread(left_currency, right_currency)
    return op.create.result[op.TICKER](left_currency, spread.bid, spread.ask, market.get_last_price(left_currency))

  top_of_book: (book) ->
    result = {}
    book.store.for_levels_above undefined, (price, level) ->
      result.price = price
      false

    return result

