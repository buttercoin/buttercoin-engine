Amount = require('./amount')
Ratio = require('./ratio')
UUID = require('node-uuid')

module.exports = class Order
  constructor: (@account, @offered_currency, @offered_amount, @received_currency, @received_amount, @uuid=UUID.v4()) ->
    throw new Error("offered amount must be an Amount object") unless @offered_amount.constructor is Amount
    throw new Error("received amount must be an Amount object") unless @received_amount.constructor is Amount
    @price = Ratio.take(@offered_amount, @received_amount)

  clone: (reversed=false) =>
    new Order(
      @account,
      if reversed then @received_currency else @offered_currency,
      if reversed then @received_amount   else @offered_amount,
      if reversed then @offered_currency  else @received_currency,
      if reversed then @offered_amount    else @received_amount,
      if reversed then undefined          else @uuid)

  split: (amount) =>
    r_amount = @received_amount.divide(@offered_amount).multiply(amount)

    filled = new Order(
      @account,
      @offered_currency, amount,
      @received_currency, r_amount,
      @uuid)

    remaining = new Order(
      @account,
      @offered_currency, @offered_amount.subtract(amount),
      @received_currency, @received_amount.subtract(r_amount))

    return [filled, remaining]

  free: =>
    Amount.put @offered_amount
    Amount.put @received_amount
    Ratio.put @price

  ###
  # create_snapshot
  #
  # Creates a snapshot of the datastore for serialization
  ###
  create_snapshot: =>
    return {
      # XXX - should use accessor to ensure instance
      account_id: if @account.uuid then @account.uuid else @account
      offered_currency: @offered_currency,
      offered_amount: @offered_amount.toString(),
      received_currency: @received_currency,
      received_amount: @received_amount.toString(),
      uuid: @uuid }

  ###
  # DataStore.load_snapshot
  #
  # Restore the state of the datastore from a snapshot
  ###
  @load_snapshot: (data) =>
    return new Order(
      #Account.load_snapshot(data.account),
      # TODO - enable account lookup from ID
      data.account_id,
      data.offered_currency,
      Amount.take(data.offered_amount),
      data.received_currency,
      Amount.take(data.received_amount),
      data.uuid)
