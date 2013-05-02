test.uses "QueryInterface",
          "Datastore.BalanceSheet",
          "Datastore.SuperMarket",
          "Datastore.Amount",
          "Datastore.Account",
          "Datastore.Market",
          "Datastore.Book"

describe "QueryInterface", ->
  setup_mocking()

  beforeEach ->
    @balancesheet = @mockify new BalanceSheet()
    @supermarket = @mockify new SuperMarket()
    @qi = new QueryInterface(@balancesheet.object, @supermarket.object)

    @mockify 'qi'

  it 'should provide an account balance', ->
    account_id = 'Fred'
    acct = @mockify new Account()
    balances = {}

    @balancesheet.expects('get_account').once().withArgs(account_id).returns(acct.object)
    for c, v of Account.supported_currencies
      if v
        balances[c] = amt Math.random()
        acct.expects('get_balance').once().withArgs(c).returns(balances[c])

    for c, v of @qi.get_balances(account_id)
      balances[c].should.equal_amount v
      delete balances[c]

    Object.keys(balances).length.should.equal 0


  it 'should provide bid and ask prices', ->
    mkt = new Market('BTC', 'USD')
    bid_price = amt '9'
    ask_price = amt '11'

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
    book.add_order(buyBTC({acct: 'fake'}, 1, 10))

    results = @qi.top_of_book(book)
    results.price.should.equal_amount amt('10')
    
