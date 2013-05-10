Q = require 'q'
DataStore = require './datastore/datastore'
Operations = require './operations'

stump = require('stump')

global_operation_serial = 0

module.exports = class ProcessingChainEntrance
  constructor: (@engine, @journal, @replication) ->
    stump.stumpify(@, @constructor.name)

  start: =>
    @info("Starting PCE")
    Q.all [
      @journal.start(@forward_operation).then =>
        @info 'INITIALIZED/REPLAYED LOG'
        null
      @replication.start() ]

  forward_operation: (operation) =>
    if not operation
      throw Error("No Operation supplied")
    if operation.serial
      if operation.serial != global_operation_serial
        throw Error("Serial Number " + operation.serial + " != " + global_operation_serial)
    operation.serial = global_operation_serial
    global_operation_serial += 1
    message = JSON.stringify(operation)
    retval = @engine.execute_operation(operation)

    return Q.all([
      @journal.record(message)
      @replication.send(message)
    ]).then =>
      @info('FORWARD DONING', retval.toString() )
      packet = {
        operation: operation
        retval: retval.toString()
      }
      return packet

