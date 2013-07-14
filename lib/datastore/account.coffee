_ = require('underscore')
Amount = require('./amount')
Order = require('./order')
UUID = require('node-uuid')

module.exports = class Account
  @supported_currencies = {
    'BTC': true,
    'USD': true
  } # TODO - move to config

  assert_valid_currency: (currency) =>
    unless @constructor.supported_currencies[currency]
      throw new Error("#{currency} is not a supported currency")

  constructor: (@uuid=UUID.v4()) ->
    @open_orders = {}
    @balances = {}

  get_balance: (currency) =>
    @assert_valid_currency(currency)
    @balances[currency]?.clone() || Amount.zero
  
  credit: (currency, amount) =>
    balance = @get_balance(currency)
    @balances[currency] = balance.add(amount)
    return @get_balance(currency)

  debit: (currency, amount) =>
    balance = @get_balance(currency)
    @balances[currency] = balance.subtract(amount)
    return @get_balance(currency)

  get_open_orders: => @open_orders

  get_order: (order_id) =>
    @open_orders[order_id]

  create_order: (offered_currency, offered_amount, received_currency, received_amount) =>
    unless @get_balance(offered_currency).compareTo(offered_amount) >= 0
      throw Error("Insufficient #{offered_currency} funds to place order")

    @debit(offered_currency, offered_amount)
    order = new Order(this, offered_currency, offered_amount, received_currency, received_amount)
    @open_orders[order.uuid] = order

    return order

  fill_order: (order) =>
    unless @open_orders[order.uuid] instanceof Order
      throw new Error("Cannot fill order #{order.uuid} (does not exist)")

    @credit(order.received_currency, order.received_amount)
    delete @open_orders[order.uuid]

  split_order: (order, amount) =>
    unless @open_orders[order.uuid] instanceof Order
      throw new Error("Cannot split order #{order.uuid} (does not exist)")
    
    [filled, remaining] = order.split(amount)
    @fill_order(filled)
    @open_orders[remaining.uuid] = remaining
    return [filled, remaining]

  cancel_order: (order) =>
    unless @open_orders[order.uuid] instanceof Order
      throw new Error("Cannot cancel order #{order.uuid} (does not exist)")

    @credit(order.offered_currency, order.offered_amount)
    delete @open_orders[order.uuid]

  ###
  # create_snapshot
  #
  # Creates a snapshot of the datastore for serialization
  ###
  create_snapshot: =>
    orders_snap = {}
    for k, v of @open_orders
      orders_snap[k] = v.create_snapshot()

    balances_snap = {}
    for k, v of @balances
      balances_snap[k] = v.toString()

    return {
      uuid: @uuid
      open_orders: orders_snap
      balances: balances_snap
    }

  ###
  # DataStore.load_snapshot
  #
  # Restore the state of the datastore from a snapshot
  ###
  @load_snapshot: (data) =>
    acct = new Account(data.uuid)

    for k, v of data.balances
      acct.balances[k] = new Amount(v)
    
    for k, v of data.open_orders
      acct.open_orders[k] = Order.load_snapshot(v)
     
    return acct
