BalanceSheet = require('./balancesheet')
SuperMarket = require('./supermarket')
Amount = require('./amount')

# Datastore exposes actual memory modifying Operations
# SYNCHRONOUS: returns when it returns!

# NON REENTRANT

# TODO - move to some core utility module
isString = (s) ->
  return typeof(s) == 'string' || s instanceof String

isNumber = (s) ->
  return typeof(s) == 'number' || s instanceof Number

module.exports = class DataStore
  constructor: (@balancesheet=(new BalanceSheet()), @supermarket=(new SuperMarket())) ->

  deposit: (args) =>
    #if not isString(args.account)
      #throw Error("Account must be a String")
    account = @balancesheet.get_account( args.account )

    amount = args.amount
    unless amount instanceof Amount
      try
        amount = Amount.take(args.amount)
      catch e
        throw Error('Only string amounts are supported in order to ensure accuracy')

    account.credit(args.currency, amount)

  place_order: (args) =>
    account = @balancesheet.get_account( args.account )
    order = account.create_order(args.offered_currency, args.offered_amount, args.received_currency, args.received_amount)
    @supermarket.route_order(order)

  ###
  # cancel_order
  # 
  # Cancels an open order.
  # Will raise an error if an order doesn't exist to be canceled.
  #
  # account_id: an identifier used to look up the account associated with an order
  # order_id: the identifier for a specific order to cancel
  ###
  cancel_order: (account_id, order_id) =>
    account = @balancesheet.get_account( account_id )
    order = account.get_order(order_id)
    market = @supermarket.get_market(order.offered_currency, order.received_currency)
    market.cancel_order(order)

  ###
  # create_snapshot
  #
  # Creates a snapshot of the datastore for serialization
  ###
  create_snapshot: =>
    return {
      balancesheet: @balancesheet.create_snapshot()
      supermarket: @supermarket.create_snapshot()
    }

  ###
  # DataStore.load_snapshot
  #
  # Restore the state of the datastore from a snapshot
  ###
  @load_snapshot: (data) =>
    ds = new DataStore()
    ds.balancesheet = BalanceSheet.load_snapshot(data.balancesheet)
    ds.supermarket = SuperMarket.load_snapshot(data.supermarket)
    return ds

