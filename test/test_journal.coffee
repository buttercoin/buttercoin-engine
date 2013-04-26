Q = require('q')
QFS = require("q-io/fs")
fs = require 'fs'
Journal = require '../lib/journal'
Ops = require '../lib/operations'

logger = require('../lib/logger')

kTestFilename = 'test.log'

describe 'Journal', ->
  setup_mocking(this)
  beforeEach ->
    TestHelper.remove_log(kTestFilename)
    @journal = new Journal(kTestFilename)

  afterEach ->
    TestHelper.remove_log(kTestFilename)
  
  it 'should create a log file if it doesn\'t exist', (done) ->
    @mockify 'journal'
    @_journal.expects('initialize_log').once().withArgs()
    @journal.start().then =>
      done()

  it 'should replay a log file if it already exists', (done) ->
    @mockify 'journal'
    exists_stub = sinon.stub(QFS, 'exists')
    exists_stub.returns {then: (cb) -> cb(true)}

    execute_operation = ->
    @_journal.expects('replay_log').once().withArgs(execute_operation).returns
      then: (cb) -> cb()
    @_journal.expects('initialize_log').once().withArgs("a")
    @journal.start(execute_operation).then =>
      exists_stub.restore()
      done()

  it 'should flush the log file when shutting down', (done) ->
    fakefile = {}

    qmock = @mockify(Q)
    # WARNING - this is not order sensitive...
    qmock.expects('nfcall').once().withArgs(fs.fsync, fakefile).returns
      then: (cb) -> cb()
    qmock.expects('nfcall').once().withArgs(fs.close, fakefile).returns
      then: (cb) -> cb()

    @journal.writefd = fakefile
    @journal.shutdown() #.then =>
    expect(@journal.writefd).to.equal null
    done()

  it 'should open the log file when initializing', (done) ->
    fakefile = {}

    qmock = @mockify(Q)
    qmock.expects('nfcall').once().withArgs(fs.open, kTestFilename, "w").returns
      then: (cb) -> cb(fakefile)

    @journal.initialize_log() #.then =>
    expect(@journal.writefd).to.equal fakefile
    done()

  describe '.replay_log', ->
    xit 'should open the log file in read mode'
    xit 'should raise an error if the read fails'
    xit 'should execute a callback for each log item'

  describe '.record', ->
    xit 'should return an empty promise when there is no open log file'
    xit 'should write a valid log item'
    xit 'should raise an error on an invalid log item'

  it 'should initialize', (finish) ->
    @journal.start( (op) =>
      console.log 'EXECUTE OP', op
    ).then =>
      console.log 'FINISHED'
      assert @journal.filename is kTestFilename
      @journal.shutdown().then =>
        finish()
    .done()

  it 'should initialize if the log file already exists', (finish) ->
    logger.info('test journal')
    journal = new Journal( kTestFilename )
    journal.start((op) =>
      console.log 'EXECUTE OP', op
    ).then =>
      # logger.info('STARTED 1')
      assert journal.filename is kTestFilename
      journal.shutdown().then =>
        journal.start((op) =>
          console.log 'EXECUTE OP', op
        ).then =>
          # logger.info('STARTED 2')
          assert journal.filename is kTestFilename
          journal.shutdown().then =>
            finish()
    .done()

  it 'should record a message correctly', (finish) ->
    journal = new Journal( kTestFilename )
    journal.start((op) =>
      console.log 'EXECUTE OP', op
    ).then =>
      raw_msg = [ Ops.ADD_DEPOSIT, "fake" ]
      msg = JSON.stringify(raw_msg)
      journal.record msg
    .then =>
      journal.flush()
      journal.shutdown().then =>
        assert fs.existsSync kTestFilename
        finish()
    .done()
