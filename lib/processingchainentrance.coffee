Q = require 'q'
DataStore = require './datastore/datastore'
Operations = require './operations'

logger = require('../lib/logger')

module.exports = class ProcessingChainEntrance
  constructor: (@engine, @journal, @replication) ->

  start: =>
    Q.all [
      @journal.start(@forward_operation)
      @replication.start() ]

  forward_operation: (operation) =>
    message = JSON.stringify(operation)
    Q.all([
      @journal.record(message)
      @replication.send(message)
    ]).then(=> Q @engine.execute_operation(operation))

