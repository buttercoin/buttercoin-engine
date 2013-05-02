module.exports = class QueryInterface
  constructor: (@balancesheet) ->
    
  get_balances: (account_id) =>
    acct = @balancesheet.get_account(account_id)
    results = {}
    for c, v of Account.supported_currencies
      results[c] = acct.get_balance(c) if v
    return results
