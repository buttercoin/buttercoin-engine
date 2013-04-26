Amount = require('./amount')

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

  get_balance: (currency, unsafe=false) =>
    @assert_valid_currency(currency)

    @balances[currency] || new Amount('0')
    #@balances[currency].clone()

  credit: (currency, amount) =>
    balance = @get_balance(currency)
    @balances[currency] = balance.add(amount)
    return @get_balance(currency)

  debit: (currency, amount) =>
    balance = @get_balance(currency)
    @balances[currency] = balance.subtract(amount)
    return @get_balance(currency)

