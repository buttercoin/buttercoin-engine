Q = require('q')

operations = require('./operations')

DataStore = require('./datastore/datastore')

module.exports = class TradeEngine
  constructor: ->
    @datastore = new DataStore

  execute_operation: (op) ->
    # Makes calls into datastore
    if op.kind == operations.ADD_DEPOSIT
      return @datastore.deposit( op )
    else
      throw Error("Unknown Operation" + JSON.stringify(op))

