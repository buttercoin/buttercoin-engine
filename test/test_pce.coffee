ProcessingChainEntrance = require('../lib/pce')
TradeEngine = require('../lib/trade_engine')
Journal = require('../lib/journal')

kTestFilename = 'test.log'

describe 'ProcessingChainEntrance', ->
  setup_mocking()

  beforeEach ->
    @journal = new Journal(kTestFilename)
    @replication = {start: (->), send: (->)}
    @engine = new TradeEngine()

    @mockify 'journal'
    @mockify 'replication'
    @mockify 'engine'

    @pce = new ProcessingChainEntrance(@engine, @journal, @replication)

  it 'should intialize the transaction log and replication when starting', (done) ->
    @_journal.expects('start').once().returns(then: ->)
    @_replication.expects('start').once().returns(then: ->)

    @pce.start()
    done()

  it 'should log, replicate, and execute a messge upon receiving it', (done) ->
    deferred = Q.defer()
    deferred.resolve(undefined)

    operation = {kind: "TEST"}
    messageJson = JSON.stringify(operation)
    @_journal.expects('record').once().withArgs(messageJson).returns(deferred.promise)
    @_replication.expects('send').once().withArgs(messageJson).returns(deferred.promise)
    @_engine.expects('execute_operation').once().withArgs(operation).returns("success")

    onComplete = (result) ->
      result.retval.should.equal "success"
      result.operation.should.equal operation
      done()

    @pce.forward_operation(operation).then(onComplete).done()

  it 'should throw an error immediately when the execution fails', (done) ->
    expect =>
      @pce.forward_operation(null).done()
    .to.throw "Invalid Operation"
    done()
