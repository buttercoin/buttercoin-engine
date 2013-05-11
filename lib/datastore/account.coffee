Amount = require('./amount')
Order = require('./order')

module.exports = class Account
  @supported_currencies = {
    'BTC': true,
    'USD': true
  } # TODO - move to config

  assert_valid_currency: (currency) =>
    unless @constructor.supported_currencies[currency]
      throw new Error("#{currency} is not a supported currency")

  constructor: ->
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

  create_order: (offered_currency, offered_amount, received_currency, received_amount) =>
    unless @get_balance(offered_currency).compareTo(offered_amount) >= 0
      throw Error("Insufficient #{offered_currency} funds to place order")

    @debit(offered_currency, offered_amount)
    return new Order(this, offered_currency, offered_amount, received_currency, received_amount)

