for op in ['ADD_DEPOSIT', 'WITHDRAW_FUNDS', 'CREATE_LIMIT_ORDER',
           'CANCEL_ORDER', 'GET_BALANCES', 'OPEN_ORDERS',
           'ORDER_INFO', 'BALANCES', 'TICKER', 'SEND_BITCOINS']
  module.exports[op] = op

op = module.exports

create_results = {
  ADD_DEPOSIT: ->

  BALANCES: (account_id, balances) ->
    result: op.BALANCES
    account: account_id
    balances: balances

  OPEN_ORDERS: (account_id, orders) ->
    result: op.OPEN_ORDERS
    account: account_id
    orders: orders

  TICKER: (currency, bid, ask, last) ->
    result: op.TICKER
    currency: currency
    bid: bid
    ask: ask
    last: last
}

module.exports.create = {
  result: create_results
}
