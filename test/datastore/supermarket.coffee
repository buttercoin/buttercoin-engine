test.uses "Datastore.SuperMarket",
          "Datastore.Market",
          "Datastore.Order",
          "Datastore.Amount"

describe 'SuperMarket', ->
  setup_mocking()
  
  beforeEach ->
    @supermarket = new SuperMarket()

    @mockify 'supermarket'

  it 'should initialize with no markets', ->
    Object.keys(@supermarket.markets).should.be.empty

  it 'should be able to route an order to the appropriate market', ->
    order = new Order('USD', amt('10'), 'BTC', amt('1'))
    market = @mockify new Market('BTC', 'USD')

    @_supermarket.expects('get_market').once().withArgs('USD', 'BTC').returns(market.object)
    market.expects('add_order').once().withArgs(order)

    @supermarket.route_order(order)

  it 'should fail when asked for a market with the same currency on both sides', ->
    expect =>
      @supermarket.get_market('USD', 'USD')
    .to.throw("USD|USD is not a valid market")

  it 'should create a market when asked for it if it doesn\'t exist', ->
    market = @supermarket.get_market('USD', 'BTC')
    market.should.be.an.instanceOf Market
    market.left_currency.should.equal 'BTC'
    market.right_currency.should.equal 'USD'

    @supermarket.markets["BTC|USD"].should.equal market

  it 'should return an existing market when it already exists', ->
    market = @supermarket.get_market('USD', 'BTC')
    market.should.equal @supermarket.get_market('USD', 'BTC')
    market.should.equal @supermarket.get_market('BTC', 'USD')

  xit 'should add new market instances as they are requested if and only if they dont already exist', ->
    supermarket = new SuperMarket()

    # get_market should return instances of Market
    btceur_market = supermarket.get_market('BTCEUR')
    btceur_market.should.be.an.instanceOf(Market)
    btcusd_market = supermarket.get_market('BTCUSD')
    btcusd_market.should.be.an.instanceOf(Market)
    usdeur_market = supermarket.get_market('USDEUR')
    usdeur_market.should.be.an.instanceOf(Market)

    # markets should be different instances
    usdeur_market.should.not.equal(btceur_market)
    usdeur_market.should.not.equal(btcusd_market)
    btceur_market.should.not.equal(btcusd_market)

    # get the markets again and should get the same instances
    another_btceur_market = supermarket.get_market('BTCEUR')
    another_btceur_market.should.equal(btceur_market)
    another_btcusd_market = supermarket.get_market('BTCUSD')
    another_btcusd_market.should.equal(btcusd_market)
    another_usdeur_market = supermarket.get_market('USDEUR')
    another_usdeur_market.should.equal(usdeur_market)
