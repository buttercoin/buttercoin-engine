map_queue = (queue, f) ->
  return queue unless queue.constructor.name is 'Dequeue'
  cur = queue.head.next
  result = []
  while(cur isnt queue.tail)
    d = cur.data
    cur = cur.next
    result.push f(d)
  return result
module.exports.map_queue = map_queue

queue_to_list = (queue) ->
  map_queue(queue, (x) -> x)

module.exports.queue_to_list = queue_to_list

serialize = (obj) ->
  return obj unless obj
  if obj.constructor.name in ['String', 'Number', 'Boolean']
    return obj

  if obj.constructor.name is 'Array'
    return (
      for x in obj
        serialize(x))

  if obj.constructor.name is 'Dequeue'
    return serialize(queue_to_list(obj))

  if obj.create_snapshot instanceof Function
    return obj.create_snapshot()

  result = {}
  for k, v of obj
    unless v instanceof Function
      result[k] = serialize(v)

  return result

module.exports.serialize = serialize
