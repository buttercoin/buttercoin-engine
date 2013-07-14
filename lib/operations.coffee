for op in ['ADD_DEPOSIT', 'WITHDRAW_FUNDS', 'CREATE_LIMIT_ORDER',
           'CANCEL_ORDER', 'GET_BALANCES', 'OPEN_ORDERS',
           'ORDER_INFO', 'BALANCES', 'TICKER']
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
}

module.exports.create = {
  result: create_results
}
