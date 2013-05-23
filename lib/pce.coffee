Q = require 'q'
DataStore = require './datastore/datastore'
Operations = require './operations'

stump = require('stump')

module.exports = class ProcessingChainEntrance
  constructor: (@engine, @journal) ->
    stump.stumpify(this, @constructor.name)
    @global_operation_serial = 0

  start: =>
    @info("Starting PCE")
    Q.all [
      @journal.start(@forward_operation, @load_snapshot).then =>
        @info 'INITIALIZED/REPLAYED LOG'
        null
    ]

  forward_operation: (operation) =>
    if not operation
      throw Error("No Operation supplied")
    if operation.serial
      if operation.serial != @global_operation_serial
        @error "Serial Number " + operation.serial + " != " + @global_operation_serial
        throw Error("Serial Number " + operation.serial + " != " + @global_operation_serial)
    operation.serial = @global_operation_serial
    @info "Bumping serial to:", @global_operation_serial
    @global_operation_serial += 1
    message = JSON.stringify(operation)
    retval = @engine.execute_operation(operation)

    return Q.all([
      @journal.record(message)
    ]).then =>
      @info('FORWARDING', retval.toString() )
      packet = {
        operation: operation
        retval: retval.toString()
      }
      return packet

  create_snapshot: =>
    deferred = Q.defer()
    deferred.resolve
      serial: @global_operation_serial
      snapshot: @engine.datastore.create_snapshot()
    return deferred.promise

  load_snapshot: (data) =>
    @info "PCE LOADING SNAPSHOT"
    @global_operation_serial = data.serial
    @engine.datastore = DataStore.load_snapshot(data.snapshot)
    @info "PCE LOADED SNAPSHOT. EXPECTING SERIAL", @global_operation_serial

  dump_snapshot: =>
    @info "PCE DUMPING SNAPSHOT"
    @journal.initialize_log("w").then =>
      @create_snapshot().then (snapshot) =>
        @journal.record(JSON.stringify snapshot).then =>
          @info "DONE DUMPING SNAPSHOT"
