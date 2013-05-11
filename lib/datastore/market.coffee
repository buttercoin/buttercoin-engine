Order = require('./order')
Book = require('./book')

module.exports = class Market
  constructor: (@left_currency, @right_currency) ->
    @left_book = new Book()
    @right_book = new Book()

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

    unless outcome.kind is 'order_filled'
      # put in book
      results.push book.add_order(outcome.residual_order)

    results.push outcome

    return results
