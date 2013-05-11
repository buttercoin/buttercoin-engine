global.chai = require 'chai'
global.expect = chai.expect
global.assert = chai.assert
global.sinon = require('sinon')
chai.should()

global.logger = require('../lib/logger')
global.Q = require('q')
Order = require('../lib/datastore/order')
Amount = require('../lib/datastore/amount')

fs = require('fs')

chai.use (_chai, utils) ->
  chai.Assertion.addMethod 'equal_amount', (amt) ->
    obj = utils.flag(this, 'object')
    this.assert obj.eq(amt),
                "Expected #{obj} to equal #{amt}",
                "Expected #{obj} not to equal #{amt}"

  chai.Assertion.addMethod 'equal_ratio', (ratio) ->
    obj = utils.flag(this, 'object')
    this.assert obj.eq(ratio),
                "Expected #{obj} to equal #{ratio}",
                "Expected #{obj} not to equal #{ratio}"

  chai.Assertion.addMethod 'succeed_with', (kind) ->
    obj = utils.flag(this, 'object')
    this.assert obj.status is 'success',
                "Expected #\{this} to have status of success but got #{obj.status}",
                "Expected #\{this} not to have status of "
    this.assert obj.kind is kind,
                "Expected #\{this} to have kind of #{kind} but got #{obj.kind}",
                "Expected #\{this} not to have kind of #{kind} (got #{obj.kind}"


global.setup_mocking = ->
  @beforeEach ->
    @mockify ||= (key) ->
      obj = if (typeof key) is 'string' then @[key] else key
      @mocks.unshift sinon.mock(obj)
      @["_#{key}"] = @mocks[0] if (typeof key) is 'string'

      return @mocks[0]

    @mocks = []

  @afterEach ->
    for _, m of @mocks
      m.verify()
      m.restore()

class TestHelper
  constructor: ->

  @remove_log: (filename='test.log') ->
    fs.unlinkSync(filename) if fs.existsSync(filename)

global.TestHelper = TestHelper

global.buyBTC = (acct, numBtc, numDollars) ->
  new Order(acct, 'USD', new Amount(numDollars.toString()), 'BTC', new Amount(numBtc.toString()))

global.sellBTC = (acct, numBtc, numDollars) ->
  new Order(acct, 'BTC', new Amount(numBtc.toString()), 'USD', new Amount(numDollars.toString()))

global.logResults = (results) ->
  displaySold = (x) ->
    console.log "\t#{x.account.name} sold #{x.received_amount} #{x.received_currency} for #{x.offered_amount} #{x.offered_currency}"
  displayOpened = (x) ->
    console.log "\t#{x.account.name} listed #{x.received_amount} #{x.received_currency} for #{x.offered_amount} #{x.offered_currency}"
  while results.length > 0
    x = results.shift()
    if x.kind is 'order_opened' #or x.kind is 'order_partially_filled'
      displayOpened(x.order || x.residual_order)
    if x.kind is 'order_filled' or x.kind is 'order_partially_filled'
      displaySold(x.order || x.filled_order)

ensureKeys = (obj, parts) ->
  return obj if parts.length <= 1

  cur = parts.shift()
  obj[cur] ||= {}
  ensureKeys(obj[cur], parts)

global.test =
  uses: (resource...) ->
    resource.forEach (r) ->
      parts = r.split('.')
      filename = parts.map((p) -> p.toLowerCase()).join('/')

      owner = ensureKeys(global, parts)
      key = parts[parts.length - 1]
      try
        owner[key] = require("../lib/#{filename}")
      catch e
        console.log "warn: couldn't load ../lib/#{filename} for #{r}"
        # Only raise if there isn't a helper module with this name
        unless global.test.module_helpers[r]
          throw e
      finally
        global.test.module_helpers[r]?()

global.test.module_helpers =
  'Datastore.Amount': ->
    global.Amount = global.Datastore.Amount
    global.amt = (x) ->
      new global.Datastore.Amount(x?.toString())

  'Datastore.Ratio': ->
    global.Ratio = global.Datastore.Ratio

  'Datastore.Account': ->
    global.Account = global.Datastore.Account

  'Datastore.DataStore': ->
    global.DataStore = global.Datastore.DataStore

  'Datastore.BalanceSheet': ->
    global.BalanceSheet = global.Datastore.BalanceSheet

  'Datastore.SuperMarket': ->
    global.SuperMarket = global.Datastore.SuperMarket

  'Datastore.Market': ->
    global.Market = global.Datastore.Market

  'Datastore.Book': ->
    global.Book = global.Datastore.Book

  'Datastore.Order': ->
    global.Order = global.Datastore.Order

  'TradeEngine': ->
    global.TradeEngine = require("../lib/trade_engine")

  #'Journal': ->
  #  kJournalFile = 'test.log'
  #  TODO - before/after cleanup log files
