
import std/sequtils

template combinationsImpl[T](iterable: openArray[T], r: int, initCollectionMayOfCap, addToCollection) =
  ## translated from
  ## https://docs.python.org/3/library/itertools.html#itertools.combinations
  
  # TODO: rewrite the following as runnableExamples
  # combinations('ABCD', 2) → AB AC AD BC BD CD
  # combinations(range(4), 3) → 012 013 023 123

  template pool: untyped = iterable  # alias
  # as `combinations` will be called multiply times on the same set,
  # so we use toSeq only once before calling this and pass a seq in.
  let n = len(pool)
  block doYield:
    if r > n:
      break doYield

    var indices = toSeq 0..<r  # its length won't change.
    let lenInd = r
    template yieldPoolByIndices =
      var res = 
        when compiles(initCollectionMayOfCap[T](lenInd)):
          initCollectionMayOfCap[T](lenInd)
        else:
          initCollectionMayOfCap[T]()
      for i in indices:
        addToCollection res, pool[i]
      yield res
    yieldPoolByIndices
    while true:
      var i = -1
      for ii in countdown(r-1, 0):
        if indices[ii] != ii + n - r:
          i = ii
          break
      if i == -1:
        break doYield
      indices[i] += 1
      for j in i+1..<r:
        indices[j] = indices[j-1] + 1
      yieldPoolByIndices


iterator combinations*[T](iterable: openArray[T], r: int): seq[T] =
  combinationsImpl(iterable, r, newSeqOfCap, add)


template mayZeroDefault*[T](t: typedesc[T]): T =
  when declared(zeroDefault): zeroDefault(T)
  else: default(T)

proc add*[T](x, y: T): T{.inline.} = x + y
type BinOp*[T] = proc (x, y: T): T
iterator accumulate*[T](iterable: openArray[T], binop: BinOp[T] = add[T]; inital = mayZeroDefault(T)): T =
  var total = inital
  for i in iterable:
    total = binop(total, i)
    yield total

