DQ = require ('deque')
redblack = require('redblack')
Order = require('./order')
Amount = require('./amount')
Ratio = require('./ratio')

joinQueues = (front, back, withCb) ->
  withCb ||= (x) -> x
  until back.isEmpty()
    front.push withCb(back.shift())

mkCloseOrder = (order) -> {
  status: 'success'
  kind: 'order_filled'
  order: order
}

mkPartialOrder = (original_order, filled, remaining) -> {
  status: 'success'
  kind: 'order_partially_filled'
  filled_order: filled
  residual_order: remaining
  original_order: original_order
}

# BookStore provides an abstract interface for managing price levels.
# It's primary goal is to make it easier to swap store implementations when
# testing different backend performances.
#
# Once a suitable backend is found, this class should be considered for removal
class BookStore
  constructor: ->
    @tree = redblack.tree((left, right) ->
      left.compareTo(right))
    @size = 0

  get_level: (price) =>
    @tree.get(price)

  add_to_price_level: (price, order) =>
    level = @tree.get(price)

    unless level
      dq = new DQ.Dequeue()

      level = {
        size: Amount.zero
        orders: dq
      }
      @insert(price, level)

    level.orders.push(order)
    level.size = level.size.add(order.offered_amount)

  # TODO - optimize this to allow for halting
  for_levels_above: (price, cb) =>
    cursor = @tree.range(new Ratio(), price)
    running = true
    cursor.forEach (order_level, cur_price) =>
      running = cb(cur_price, order_level) if running

  insert: (price, level) =>
    @tree.insert(price, level)
    @size += 1

  delete: (price) =>
    @tree.delete(price)
    @size -= 1

  is_empty: => @size is 0

  forEach: (cb) => @tree.forEach(cb)
  
  create_snapshot: =>
    q_map = (queue, f) ->
      cur = queue.head.next
      result = []
      while(cur isnt queue.tail)
        d = cur.data
        cur = cur.next
        result.push f(d)
      return result

    levels = []
    @tree.range().forEach (order_level, cur_price) =>
      levels.push {
        price: {
          numerator: cur_price.numerator.toString(),
          denominator: cur_price.denominator.toString(),
        },
        level: {
          size: order_level.size.toString(),
          orders: q_map(order_level.orders, (x) -> x.create_snapshot())
        }
      }

    return levels

  @load_snapshot: (data) =>
    store = new BookStore()
    for level in data
      price = Ratio.take(Amount.take(level.price.numerator), Amount.take(level.price.denominator))
      level = {
        size: Amount.take(level.level.size)
        orders: level.level.orders.map Order.load_snapshot
      }
      store.insert(price, level)

    return store

module.exports = class Book
  constructor: ->
    @store = new BookStore()

  fill_orders_with: (order) =>
    orig_order = order
    order = order.clone()
    #order.price = 1/order.price

    #cur = @store.head()
    closed = []
    amount_filled = new Ratio(Amount.zero)
    amount_remaining = order.received_amount.clone()
    amount_spent = new Ratio(Amount.zero)
    results = new DQ.Dequeue()

    @store.for_levels_above order.price, (price, order_level) =>
      # close the whole price level if we can
      if order_level.size.lte(amount_remaining)
        amount_filled = amount_filled.add(order_level.size)
        amount_remaining = amount_remaining.subtract(order_level.size)
        amount_spent = amount_spent.add(price.multiply(order_level.size))

        # queue the entire price level to be closed
        closed.push({price: price, order_level: order_level})
        return true # want more price levels
      else
        # consume all orders we can at this price level, starting with the oldest
        cur_order = order_level.orders.shift()
        while cur_order?.offered_amount.lte(amount_remaining)
          amount_filled = amount_filled.add(cur_order.offered_amount)
          amount_remaining = amount_remaining.subtract(cur_order.offered_amount)
          x = price.multiply(cur_order.offered_amount)
          amount_spent = amount_spent.add(x)
          Ratio.put(x)

          order_level.size = order_level.size.subtract(cur_order.offered_amount)
          results.push mkCloseOrder(cur_order)
          
          # there must always be another order here or else we would have consumed
          # the entire price level at once
          #
          # if there isn't we have a major problem
          cur_order = order_level.orders.shift()
        
        if amount_remaining.eq(Amount.zero)
          # if we're done, put the cur_order back into the price level
          order_level.orders.unshift(cur_order)
        else if cur_order?.offered_amount.gt(Amount.zero)
          # diminish next order by remaining amount
          [filled, remaining] = cur_order.split(amount_remaining)
          order_level.size = order_level.size.subtract(amount_remaining)
          amount_filled = amount_filled.add(amount_remaining)
          amount_spent = amount_spent.add(price.multiply(amount_remaining))
          amount_remaining = Amount.zero

          # push the partially filled order back to the front of the queue
          order_level.orders.unshift(remaining)

          # report the partially filled order
          results.push mkPartialOrder(cur_order, filled, remaining)
        return false # don't want more price levels

    closed.forEach (x) =>
      joinQueues(results, x.order_level.orders, mkCloseOrder)
      @store.delete(x.price)

    order.offered_amount = amount_spent.toAmount()
    Ratio.put(order.price)
    order.price = Ratio.take(order.offered_amount, order.received_amount)
    #order.offered_amount.divide(order.received_amount)
    if amount_remaining.is_zero()
      results.push mkCloseOrder(order)
    else if amount_filled.is_zero()
      results.push {
        status: 'success'
        kind:   'not_filled'
        residual_order: orig_order
      }
      order.free()
    else
      # TODO - move to Order?
      filled = new Order(order.account,
                        order.offered_currency,
                        amount_spent.toAmount(),
                        order.received_currency,
                        amount_filled.toAmount())
      remaining = new Order(order.account,
                            order.offered_currency,
                            orig_order.price.inverse().multiply(amount_remaining).toAmount(),
                            order.received_currency,
                            new Ratio(orig_order.received_amount).subtract(amount_filled).toAmount())
      results.push mkPartialOrder(orig_order, filled, remaining)
      order.free()

    return results
  
  add_order: (order) =>
    @store.add_to_price_level(order.price, order)

    return {
      status: 'success'
      kind: 'order_opened'
      order: order
    }
  
  # XXX - unoptimized hack
  filter_deqeue = (dq, pred) ->
    result = new DQ.Dequeue()
    xs = []
    while dq.length > 0
      x = dq.shift()
      unless pred(x)
        result.push(x)
      else
        xs.push(x)
    return [result, xs]

  cancel_order: (order) =>
    level = @store.get_level(order.price)
    unless level
      throw new Error("Unable to cancel order #{order.uuid} (not found)")

    [level.orders, xs] = filter_deqeue level.orders, (x) ->
      x.uuid == order.uuid

    if xs.length is 0
      throw new Error("Unable to cancel order #{order.uuid} (not found)")

    for x in xs
      old = level.size
      level.size = old.subtract(x.offered_amount)
      Amount.put(old)
      x.account.cancel_order(x)

    if level.size.is_zero()
      @store.delete(order.price)

  create_snapshot: =>
    return {store: @store.create_snapshot()}

  @load_snapshot: (data) =>
    book = new Book()
    book.store = BookStore.load_snapshot(data.store)
    return book
