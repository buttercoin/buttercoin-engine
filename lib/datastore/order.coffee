Amount = require('./amount')
Ratio = require('./ratio')

module.exports = class Order
  constructor: (@account, @offered_currency, @offered_amount, @received_currency, @received_amount) ->
    throw new Error("offered amount must be an Amount object") unless @offered_amount.constructor is Amount
    throw new Error("received amount must be an Amount object") unless @received_amount.constructor is Amount
    @price = Ratio.take(@offered_amount, @received_amount)

  clone: (reversed=false) =>
    new Order(
      @account,
      if reversed then @received_currency else @offered_currency,
      if reversed then @received_amount   else @offered_amount,
      if reversed then @offered_currency  else @received_currency,
      if reversed then @offered_amount    else @received_amount)

  split: (amount) =>
    r_amount = @received_amount.divide(@offered_amount).multiply(amount)

    filled = new Order(
      @account,
      @offered_currency, amount,
      @received_currency, r_amount)

    remaining = new Order(
      @account,
      @offered_currency, @offered_amount.subtract(amount),
      @received_currency, @received_amount.subtract(r_amount))

    return [filled, remaining]

  free: =>
    Amount.put @offered_amount
    Amount.put @received_amount
    Ratio.put @price
    #@offered_amount = null
    #@received_amount = null
    #@price = null
