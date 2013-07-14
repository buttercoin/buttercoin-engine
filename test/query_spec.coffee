test.uses "QueryInterface",
          "Datastore.BalanceSheet",
          "Datastore.SuperMarket",
          "Datastore.Amount",
          "Datastore.Account",
          "Datastore.Ratio",
          "Datastore.Market",
          "Datastore.Book"

op = require('../lib/operations')

describe "QueryInterface", ->
  setup_mocking()

  beforeEach ->
    @balancesheet = @mockify new BalanceSheet()
    @supermarket = @mockify new SuperMarket()
    ds = {}
    ds.balancesheet = @balancesheet.object
    ds.supermarket = @supermarket.object
    @qi = new QueryInterface(ds)

    @mockify 'qi'

  it 'should provide an account balances', ->
    account_id = 'Fred'
    acct = @mockify new Account()
    balances = {}

    @balancesheet.expects('get_account').once().withArgs(account_id).returns(acct.object)
    for c, v of Account.supported_currencies
      if v
        balances[c] = amt Math.random()
        acct.expects('get_balance').once().withArgs(c).returns(balances[c])

    result = @qi.get_balances(account_id)
    result.result.should.equal op.BALANCES
    result.account.should.equal account_id
    for c, v of result.balances
      balances[c].should.equal_amount v
      delete balances[c]

    Object.keys(balances).length.should.equal 0

  it 'should provide information about an open order'
  it 'should provide information about a closed order'

  it 'should list all open orders for a given account', ->
    account_id = 'Fred'
    acct = @mockify new Account()
    orders = ["order1", "order2"]

    @balancesheet.expects('get_account').once().withArgs(account_id).returns(acct.object)
    acct.expects('get_open_orders').once().returns(orders)

    result = @qi.get_open_orders(account_id)
    result.result.should.equal op.OPEN_ORDERS
    result.account.should.equal account_id
    result.orders.should.equal orders

  it 'should provide a ticker quote', ->
    market = @mockify new Market('BTC', 'USD')
    mkt = market.object
    bid_price = new Ratio(amt '9')
    ask_price = new Ratio(amt '11')
    last_price = new Ratio(amt '10')

    @supermarket.expects('get_market').twice().withArgs('USD', 'BTC').returns(mkt)
    market.expects('get_last_price').once().withArgs('USD').returns(last_price)
    @_qi.expects('top_of_book').once().withArgs(mkt.left_book).returns(price: bid_price.inverse())
    @_qi.expects('top_of_book').once().withArgs(mkt.right_book).returns(price: ask_price)

    ticker = @qi.get_ticker('USD', 'BTC')
    ticker.result.should.equal op.TICKER
    ticker.bid.should.equal_amount bid_price
    ticker.ask.should.equal_amount ask_price
    #console.log "ticker price:", ticker.last.toString()
    ticker.last.should.equal_ratio last_price

  it 'should provide bid and ask prices', ->
    mkt = new Market('BTC', 'USD')
    bid_price = new Ratio(amt '9')
    ask_price = new Ratio(amt '11')

    @supermarket.expects('get_market').once().withArgs('BTC', 'USD').returns(mkt)
    @_qi.expects('top_of_book').once().withArgs(mkt.left_book).returns(price: bid_price)
    @_qi.expects('top_of_book').once().withArgs(mkt.right_book).returns(price: ask_price.inverse())

    spread = @qi.get_spread('BTC', 'USD')
    spread.bid.should.equal_amount bid_price
    spread.ask.should.equal_amount ask_price

    @supermarket.expects('get_market').once().withArgs('USD', 'BTC').returns(mkt)
    @_qi.expects('top_of_book').once().withArgs(mkt.left_book).returns(price: bid_price)
    @_qi.expects('top_of_book').once().withArgs(mkt.right_book).returns(price: ask_price.inverse())

    spread = @qi.get_spread('USD', 'BTC')
    spread.bid.should.equal_amount bid_price.inverse()
    spread.ask.should.equal_amount ask_price.inverse()

  it 'should be able to inspect the top of a book', ->
    book = new Book()
    book.add_order(buyBTC(new Account(), 1, 10))

    results = @qi.top_of_book(book)
    results.price.should.equal_amount amt('10')
    
