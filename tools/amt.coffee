# Array mapped trie, high-to-low, to keep order
# needs compression

[Some, None] = ((opt) -> [opt.Some, opt.None])(require './option')
sys = require 'sys'

exports.arraySubst = arraySubst = (a, i, v) ->
  newArray = a.slice(0, a.length)
  newArray[i] = v
  newArray

class EmptyAMT
  size: 0
  shift: 30
  entries: None for i in [0...32]
  get: (i) -> None
  put: (i, v) -> @putWithShift(i, Some(v), 30)
  remove: (i) -> @putWithShift(i, None, 30)
  putWithShift: (i, v, shift) ->
    shifted = i >> shift
    index = shifted & 31
    if (i & ((1 << shift) - 1)) == 0
      if @size == 1 and v == None
        return @empty
      if @entries[index] == v
        return this
#      sys.puts "leaf AMT(shift: #{shift}) for put: #{i}"
      return new AMT(shift, arraySubst(@entries, index, v), @children, @size + 1)
    else
      child = @children[index].putWithShift(i, v, shift - 5)
      if child == @children[index]
        return this
      newSize = @size + child.size - @children[index].size
      if newSize == 0
        return @empty
#      sys.puts "inner AMT(shift: #{shift}) for put: #{i}"
      return new AMT(shift, @entries, arraySubst(@children, index, child), newSize)
  map: (f) -> this
  flatMap: (f) -> this
  forEach: (f) ->
  toString: -> t = this; "AMT(#{t.contents()})"
  contents: ->
    r = []
    @forEach (i) -> r.push i
    r.join ', '

exports.EmptyAMT = empty = new EmptyAMT
EmptyAMT.prototype.empty = empty
EmptyAMT.prototype.children = (empty for i in [0...32])
EmptyAMT.prototype.putWithShiftMutable = EmptyAMT.prototype.putWithShift

class AMT extends EmptyAMT
  constructor: (@shift, @entries, @children, @size) ->
  get: (i) ->
    shifted = i >> @shift
    index = shifted & 31
    if shifted == index then @entries[index] else @children[index].get(i)
  putWithShiftMutable: (i, v, shift) ->
    shifted = i >> shift
    index = shifted & 31
    if shifted == index
      if @entries[index] != v
        @entries[index] = v
        if v == None
          @size--
        else
          @size++
    else
      oldSize = @children[index].size
      @children[index] = @children[index].putWithShiftMutable(i, v, shift - 5)
      @size += @children[index].size - oldSize
    return if @size == 0 then @empty else this
  map: (f) ->
    newEntries = @entries.map f
    newChildren = @children.map (child) -> child.map f
    new AMT(@shift, newEntries, newChildren)
  flatMap: (f) ->
    ret = @empty
    index = 0
    @forEach (x) -> f(x).forEach (s) -> ret = ret.putWithShiftMutable index++, s, 0
    ret
  forEach: (f) ->
    @entries.forEach (x) -> x.forEach f
    @children.forEach (c) -> c.forEach f
