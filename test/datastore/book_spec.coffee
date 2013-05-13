test.uses "Datastore.Amount",
          "Datastore.Book",
          "Datastore.Order",
          "Datastore.Ratio"
          
sellBTC = (args...) ->
  order = global.sellBTC(args...)
  order.price = order.price.inverse()
  return order

describe 'Book', ->
  beforeEach ->
    @book = new Book()
    @account1 = {name: "acct1"}
    @account2 = {name: "acct2"}

  it 'should be able to add an order', ->
    order = buyBTC(@account1, 1, 10)
    @book.store.is_empty().should.be.true
    result = @book.add_order(order)
    @book.store.is_empty().should.be.false

    expect(result).to.exist
    result.should.succeed_with('order_opened')
    result.order.should.equal(order)

  it 'should be able to open a higher order', ->
    @book.add_order buyBTC(@account1, 2, 20)
    result = @book.add_order buyBTC(@account1, 1, 11)
    result.should.succeed_with('order_opened')

    expectedBTC = [2, 1].map amt
    expectedUSD = [20, 11].map amt
    expectedLevels = [10, 11].map amt
    # TODO sizes and prices should be inverse of one another?
    expectedSizes = [20, 11].map amt
    @book.store.forEach (order_level, price) ->
      price.should.equal_ratio expectedLevels.shift()
      order_level.size.should.equal_amount expectedSizes.shift()

      until order_level.orders.isEmpty()
        order = order_level.orders.shift()
        order.received_amount.should.equal_amount expectedBTC.shift()
        order.offered_amount.should.equal_amount expectedUSD.shift()

  it 'should be able to open a lower order', ->
    @book.add_order buyBTC(@account1, 2, 20)
    result = @book.add_order buyBTC(@account1, 1, 9)
    result.should.succeed_with('order_opened')

    expectedLevels = [9, 10].map amt
    expectedSizes = [9, 20].map amt
    @book.store.forEach (order_level, price) ->
      price.should.equal_amount expectedLevels.shift()
      order_level.size.should.equal_amount expectedSizes.shift()

  it 'should preserve the order in which orders are received', ->
    @book.add_order(sellBTC(@account1, 1, 10))
    @book.add_order(sellBTC(@account2, 1, 10))
    results = @book.fill_orders_with(buyBTC({name: 'acct3'}, 1, 10))
    results.should.have.length(2)

    sold = results.shift()
    sold.should.succeed_with('order_filled')
    sold.order.account.should.equal(@account1)

  it 'should be able to match an order', ->
    @book.add_order(sellBTC(@account1, 1, 10))
    results = @book.fill_orders_with(buyBTC(@account2, 1, 10))
    @book.store.is_empty().should.be.true
    
    results.should.have.length(2)
    sold = results.shift()
    sold.should.succeed_with('order_filled')
    sold.order.account.should.equal(@account1)

    bought = results.shift()
    bought.should.succeed_with('order_filled')
    bought.order.account.should.equal(@account2)

  it 'should be able to partially close an open order', ->
    @book.add_order(sellBTC(@account1, 2, 2))
    results = @book.fill_orders_with(buyBTC(@account2, 1, 1))
    @book.store.is_empty().should.be.false
    results.should.have.length(2)

    bought = results.shift()
    bought.should.succeed_with('order_partially_filled')
    bought.original_order.account.should.equal(@account1)
    bought.filled_order.account.should.equal(@account1)
    bought.residual_order.account.should.equal(@account1)

    sold = results.shift()
    sold.should.succeed_with('order_filled')
    sold.order.account.should.equal(@account2)

    # TODO - move sum checks to spec for Order.split
    sum = bought.filled_order.offered_amount.add(bought.residual_order.offered_amount)
    sum.should.equal_amount(bought.original_order.offered_amount)

    sum = bought.filled_order.received_amount.add(bought.residual_order.received_amount)
    sum.should.equal_amount(bought.original_order.received_amount)

    @book.fill_orders_with(buyBTC(@account2, 1, 1))
    @book.store.is_empty().should.be.true

  it 'should be able to partially fill a new order', ->
    # TODO - sell must always be first!
    @book.add_order(buyBTC(@account1, 1, 1))
    results = @book.fill_orders_with(sellBTC(@account2, 3, 3))
    results.should.have.length(2)
    filled = results.shift()
    filled.should.succeed_with('order_filled')
    filled.order.account.should.equal(@account1)

    partial = results.shift()
    partial.should.succeed_with('order_partially_filled')
    partial.original_order.account.should.equal(@account2)
    partial.filled_order.account.should.equal(@account2)
    partial.residual_order.account.should.equal(@account2)

  it 'should indicate that there are not matches when orders don\'t overlap', ->
    @book.add_order(sellBTC(@account1, 1, 40))
    result = @book.fill_orders_with(buyBTC(@account2, 1, 20))
    result.should.have.length(1)
    result = result.shift()
    result.should.succeed_with('not_filled')
    result.residual_order.account.should.equal(@account2)

  it 'should report the correct closing price when closing a mismatched order', ->
    order1 = sellBTC(@account1, 1, 10)
    @book.add_order(order1)
    results = @book.fill_orders_with(buyBTC(@account2, 1, 11))
    results.should.have.length(2)
    original = results.shift()
    original.should.succeed_with('order_filled')
    original.order.account.should.equal(@account1)
    original.order.price.should.equal_amount(order1.price)
    
    filling = results.shift()
    filling.should.succeed_with('order_filled')
    filling.order.account.should.equal(@account2)
    filling.order.price.should.equal_amount(order1.price)


  xit 'should partially fill across price levels and provide a correct residual order', ->
    @book.add_order(sellBTC(@account1, '1', '11'))
    @book.add_order(sellBTC(@account1, '1', '12'))
    @book.add_order(sellBTC(@account1, '1', '13'))

    buy_amt = amt '4'
    buy_price = amt '14'
    offered_amt = buy_price.multiply(buy_amt)
    results = @book.fill_orders_with(buyBTC(@account2, buy_amt, offered_amt))
    results.length.should.equal(4)

    closed = results.shift()
    closed.should.succeed_with('order_filled')
    closed.order.price.should.equal_amount(amt '11')

    closed = results.shift()
    closed.should.succeed_with('order_filled')
    closed.order.price.should.equal_amount(amt '12')

    closed = results.shift()
    closed.should.succeed_with('order_filled')
    closed.order.price.should.equal_amount(amt '13')

    partial = results.shift()
    partial.should.succeed_with('order_partially_filled')
    partial.filled_order.price.should.equal_amount(amt '12')
    partial.filled_order.received_amount.should.equal_amount(amt '3')
    partial.filled_order.offered_amount.should.equal_amount(amt(12*3))

    partial.residual_order.price.should.equal_ratio(Ratio.take(buy_price).inverse())
    partial.residual_order.received_amount.should.equal_amount(amt '1')
    partial.residual_order.offered_amount.should.equal_ratio(Ratio.take(buy_price).inverse())

  it 'should be able to cancel an open order', ->
    order = sellBTC(@account1, '1', '10')
    @account1.cancel_order = ->

    @book.add_order(order)
    @book.cancel_order(order)
    @book.store.is_empty().should.equal true
    
  it 'should fail when trying to cancel an order that doesn\'t exist', ->
    order = sellBTC(@account1, '1', '10')
    @account1.cancel_order = ->
       
    expect =>
      @book.cancel_order(order)
    .to.throw "Unable to cancel order #{order.uuid} (not found)"

    @book.add_order(sellBTC(@account1, '1', '10'))
    expect =>
      @book.cancel_order(order)
    .to.throw "Unable to cancel order #{order.uuid} (not found)"

  xit 'should handle random orders and end up in a good state', ->
    # TODO - write a 'canonical' simulation for the book, throw random data at both, verify
    
