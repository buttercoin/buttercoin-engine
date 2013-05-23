ProcessingChainEntrance = require('../lib/pce')
TradeEngine = require('../lib/trade_engine')
Journal = require('../lib/journal')

kTestFilename = 'test.log'

describe 'ProcessingChainEntrance', ->
  setup_mocking()

  beforeEach ->
    @journal = new Journal(kTestFilename)
    @engine = new TradeEngine()

    @mockify 'journal'
    @mockify 'engine'

    @pce = new ProcessingChainEntrance(@engine, @journal)

  it 'should intialize the transaction log and when starting', (finish) ->
    @_journal.expects('start').once().returns(then: ->)

    @pce.start()
    finish()

  it 'should log and execute a message upon receiving it', (finish) ->
    deferred = Q.defer()
    deferred.resolve(undefined)

    operation = {kind: "TEST"}
    operationResult = {kind: "TEST", serial: 0}
    messageJsonResult = JSON.stringify(operationResult)

    @_journal.expects('record').once().withArgs(messageJsonResult).returns(deferred.promise)
    @_engine.expects('execute_operation').once().withArgs(operationResult).returns("success")

    onComplete = (result) ->
      result.retval.should.equal "success"
      result.operation.should.equal operation
      finish()

    @pce.forward_operation(operation).then(onComplete).done()

  it 'should fail when encountering an out of order serial', (finish) ->
    deferred = Q.defer()
    deferred.resolve(undefined)

    operation1 = {kind: "TEST"}
    operationResult1 = {kind: "TEST", serial: 0}
    messageJsonResult1 = JSON.stringify(operationResult1)

    @_journal.expects('record').once().withArgs(messageJsonResult1).returns(deferred.promise)
    @_engine.expects('execute_operation').once().withArgs(operationResult1).returns("success")

    operation5 = {kind: "TEST", serial: 5}

    onComplete1 = (result) ->
      result.retval.should.equal "success"
      result.operation.should.equal operation1
      true

    @pce.forward_operation(operation1).then(onComplete1).then =>
      expect =>
        @pce.forward_operation(operation5)
      .to.throw "Serial Number 5 != 1"
      finish()
    .done()

  it 'should throw an error immediately when operation is null', (finish) ->
    expect =>
      @pce.forward_operation(null).done()
    .to.throw "No Operation supplied"
    finish()

  it 'should throw an error immediately when the execution fails', (finish) ->
    expect =>
      @pce.forward_operation({'foo': 'bar'}).done()
    .to.throw "Invalid Operation"
    finish()
