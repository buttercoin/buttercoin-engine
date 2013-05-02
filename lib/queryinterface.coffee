module.exports = class QueryInterface
  constructor: (@balancesheet, @supermarket) ->
    
  get_balances: (account_id) =>
    acct = @balancesheet.get_account(account_id)
    results = {}
    for c, v of Account.supported_currencies
      results[c] = acct.get_balance(c) if v
    return results

  get_spread: (left_currency, right_currency) ->
    market = @supermarket.get_market(left_currency, right_currency)

    books = [market.left_book, market.right_book]
    prices = books.map (x) => @top_of_book(x).price
    #prices = prices.reverse() if market.left_currency isnt left_currency

    #prices[0] = prices[0].inverse() if market.left_currency 

    if market.left_currency is left_currency
      prices[1] = prices[1].inverse()
    else
      prices[0] = prices[0].inverse()


    return {
      bid: prices[0]
      ask: prices[1] #.inverse()
    }

  top_of_book: (book) ->
    result = {}
    book.store.for_levels_above undefined, (price, level) ->
      result.price = price
      false

    return result

