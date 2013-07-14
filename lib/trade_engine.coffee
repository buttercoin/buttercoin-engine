Q = require('q')
op = require('./operations')
DataStore = require('./datastore/datastore')
Amount = require('./datastore/amount')

module.exports = class TradeEngine
  constructor: ->
    @datastore = new DataStore()
    @operation_handlers = {}
    @operation_handlers[op.ADD_DEPOSIT] = (op) => @datastore.deposit(op)
    @operation_handlers[op.WITHDRAW_FUNDS] = (op) => @datastore.withdraw(op)
    @operation_handlers[op.CREATE_LIMIT_ORDER] = @datastore.place_order #(op) => @datastore.place_order(op)

  execute_operation: (op) =>
    unless op?.kind
      throw Error("Invalid Operation: " + JSON.stringify(op))

    # Makes calls into datastore
    if @operation_handlers[op.kind]
      return @operation_handlers[op.kind](op)
    else
      throw Error("Unknown Operation: " + JSON.stringify(op))

