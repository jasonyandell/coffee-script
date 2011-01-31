# A monad indicating the absence of a value
exports.None = None =
  isNone: true

  same: (o) -> o == this

  length: 0

  has: (v) -> false

  map: (f) -> this

  flatMap: (f) -> this

  filter: (f) -> this

  forEach: (f) ->

  toString: -> 'None'

  noneSome: (nF, sF) -> nF()

  reduce: (f, v) -> v

# A monad indicating the presence of a value
class Some
  constructor: (value) -> this[0] = value

  isNone: false

  same: (o) -> o instanceof Some and o.has this[0]

  has: (v) -> this[0] is v

  length: 1

  flatMap: (func) ->
    res = func(this[0])
    if res.length == 1
      return res
    else
      ret = []
      for item in res
        for element in item
          ret.push element
      return ret

  map: (f) -> new Some(f(this[0]))

  filter: (f) -> if f(this[0]) then this else None

  forEach: (f) -> f(this[0])

  toString: -> "Some(#{this[0]})"

  noneSome: (nF, sF) -> sF(this[0])

  reduce: (f, v) -> f(v, this[0])

Array.prototype.find = (f) ->
  for i in this
    if f(i)
      return new Some(i)
  return None

exports.Some = (x) -> new Some(x)
