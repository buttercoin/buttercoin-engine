Q = require 'q'
DataStore = require './datastore/datastore'
Operations = require './operations'

stump = require('stump')

module.exports = class ProcessingChainEntrance
  constructor: (@engine, @journal, @replication) ->

  start: =>
    stump.info("Starting PCE")
    Q.all [
      @journal.start(@forward_operation).then =>
        stump.info 'INITIALIZED/REPLAYED LOG'
        null
      @replication.start() ]

  forward_operation: (operation) =>
    message = JSON.stringify(operation)
    Q.all([
      @journal.record(message)
      @replication.send(message)
    ]).then(=> Q @engine.execute_operation(operation))

