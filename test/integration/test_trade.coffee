test.uses "trade_engine",
          "Journal",
          "pce",
          "operations",
          "logger"

BD = require('bigdecimal')
Q = require("q")

kTestFilename = 'test.log'

describe 'TradeEngine', ->
  beforeEach =>
    TestHelper.remove_log(kTestFilename)

  afterEach =>
    TestHelper.remove_log(kTestFilename)

  xit 'can perform deposit', (finish) ->
    deferred = Q.defer()
    deferred.resolve(undefined)

    replicationStub =
      start: sinon.stub()
      send: sinon.stub().returns(deferred.promise)

    pce = new ProcessingChainEntrance(new TradeEngine(),
                                      new Journal(kTestFilename),
                                      replicationStub)
    pce.start().then ->
      logger.info('Started PCE')
      pce.forward_operation
        kind: operations.ADD_DEPOSIT
        account: 'Peter'
        currency: 'USD'
        amount: 200.0
      .then =>
        finish()
    .done()
