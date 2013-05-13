test.uses "Datastore.Market",
          "Datastore.Book",
          "Datastore.Order",
          "Datastore.Amount"

describe 'Market', ->
  bob = {name: 'bob'}
  sue = {name: 'sue'}
  jen = {name: 'jen'}

  beforeEach ->
    @market = new Market('BTC', 'USD')

  it 'should initialize with a buy book and a sell book', ->
    @market.left_book.should.be.an.instanceOf(Book)
    @market.right_book.should.be.an.instanceOf(Book)

  it 'should add an order to the correct book', ->
    @market.right_book.add_order = sinon.spy()
    @market.left_book.add_order = sinon.spy()

    order1 = sellBTC(@bob, 1, 10)
    order2 = buyBTC(@sue, 1, 10)

    @market.add_order(order1)
    @market.right_book.add_order.should.have.been.calledOnce
    @market.left_book.add_order.should.not.have.been.called

    @market.add_order(order2)
    @market.left_book.add_order.should.have.been.calledOnce

  it 'should close an order if there is a full match', ->
    order1 = sellBTC(@bob, 1, 10)
    order2 = buyBTC(@sue, 1, 10)
    
    @market.add_order(order1)
    results = @market.add_order(order2)
    results.should.have.length(2)
    closed = results.shift()
    closed.kind.should.equal('order_filled')

    filled = results.shift()
    filled.kind.should.equal('order_filled')


  it 'should close an order if there are multiple partial matches', ->
    @market.add_order sellBTC(jen, 1, 10)
    @market.add_order sellBTC(sue, 1, 10)
    results = @market.add_order buyBTC(bob, 2, 20)
    results.should.have.length(3)
    
    closed = results.shift()
    closed.should.succeed_with('order_filled')
    closed = results.shift()
    closed.should.succeed_with('order_filled')
    closed = results.shift()
    closed.should.succeed_with('order_filled')

  it 'should open a partial order if demand remains after closing out other orders', ->
    @market.add_order sellBTC(jen, 1, 15)
    @market.add_order sellBTC(jen, 1, 8)
    @market.add_order sellBTC(sue, 1, 10)
    results = @market.add_order buyBTC(bob, 3, 30)

    results.should.have.length(4)

    closed = results.shift()
    closed.should.succeed_with('order_filled')
    closed.order.price.should.equal_amount(amt 8)

    closed = results.shift()
    closed.should.succeed_with('order_filled')
    closed.order.price.should.equal_amount(amt 10)

    opened = results.shift()
    opened.should.succeed_with('order_opened')
    opened.order.price.should.equal_amount(amt 10)
    opened.order.offered_amount.should.equal_amount(amt 10)
    opened.order.received_amount.should.equal_amount(amt 1)

    partial = results.shift()
    partial.should.succeed_with('order_partially_filled')
    partial.filled_order.price.should.equal_amount(amt 9)
    partial.filled_order.received_amount.should.equal_amount(amt 2)
    partial.filled_order.offered_amount.should.equal_amount(amt 18)

  it 'should be able to cancel an open order', ->
    order = sellBTC(jen, 1, 10)
    jen.cancel_order = ->

    @market.add_order order
    order.price = order.price.inverse()
    @market.cancel_order order

  xit 'should fail when trying to cancel a non-existant order', ->

  xit 'should handle random orders and end up in a good state', ->
    # TODO - write a 'canonical' simulation for the market, throw random data at both, verify

