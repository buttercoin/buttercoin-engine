_ = require('underscore')
Account = require('./account')

module.exports = class BalanceSheet
  constructor: ->
    @accounts = Object.create null

  get_account: (name) =>
    account = @accounts[name]
    if not (account instanceof Account)
      @accounts[name] = account = new Account()
    return account

  ###
  # create_snapshot
  #
  # Creates a snapshot of the datastore for serialization
  ###
  create_snapshot: =>
    result = {}
    for k, v of @accounts
      result[k] = v.create_snapshot()

    return {accounts: result}

  ###
  # DataStore.load_snapshot
  #
  # Restore the state of the datastore from a snapshot
  ###
  @load_snapshot: (data) =>
    result = new BalanceSheet()
    for k, v of data.accounts
      result.accounts[k] = Account.load_snapshot(v)

    return result
