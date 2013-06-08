Q = require('q')
operations = require('./operations')
DataStore = require('./datastore/datastore')
Amount = require('./datastore/amount')

module.exports = class TradeEngine
  constructor: ->
    @datastore = new DataStore

  execute_operation: (op) ->
    console.log "TradeEngine.execute_operation:", op
    unless op?.kind
      throw Error("Invalid Operation: " + JSON.stringify(op))

    console.log "GOT OPERATION:", op
    # Makes calls into datastore
    if op.kind is operations.ADD_DEPOSIT
      return @datastore.deposit(op)
    if op.kind is operations.CREATE_LIMIT_ORDER
      return @datastore.place_order(op)
    else
      throw Error("Unknown Operation: " + JSON.stringify(op))

