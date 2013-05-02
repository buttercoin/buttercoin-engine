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
    order = new Order({acct: 'fake'}, 'USD', amt('10'), 'BTC', amt('1'))
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

