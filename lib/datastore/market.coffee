Order = require('./order')
Book = require('./book')

module.exports = class Market
  constructor: (@left_currency, @right_currency) ->
    @left_book = new Book()
    @right_book = new Book()
    @last_order = undefined

  add_order: (order) =>
    book = null
    if order.offered_currency == @left_currency
      book = @right_book
      other_book = @left_book
    else
      book = @left_book
      other_book = @right_book

    # check against other book
    flipped_order = order.clone()
    flipped_order.price = order.price.inverse()
    results = other_book.fill_orders_with(flipped_order)
    outcome = results.pop()

    if outcome.kind is 'order_filled' or outcome.kind is 'order_partially_filled'
      @last_order = (outcome.order || outcome.filled_order)

    unless outcome.kind is 'order_filled'
      # XXX - hack, this should happen when the residual_order is made
      outcome.residual_order.uuid = order.uuid
      # put in book
      results.push book.add_order(outcome.residual_order)

    results.push outcome

    return results

  get_last_price: (currency) =>
    return null unless @last_order
    if @last_order.offered_currency is currency
      return @last_order.price
    else
      return @last_order.price.inverse()

  cancel_order: (order) =>
    book =  if order.offered_currency == @left_currency
              @right_book
            else
              @left_book
    book.cancel_order(order)

  create_snapshot: =>
    return {
      left:
        currency: @left_currency
        book: @left_book.create_snapshot()
      right:
        currency: @right_currency
        book: @right_book.create_snapshot()
    }

  @load_snapshot: (data) =>
    market = new Market(data.left.currency, data.right.currency)
    market.left_book = Book.load_snapshot(data.left.book)
    market.right_book = Book.load_snapshot(data.right.book)
    return market
