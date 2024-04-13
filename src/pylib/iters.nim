


from ./collections_abc import Iterable
from ./pybool import toBool
import ./noneType
export noneType.None

type Filter[T] = object
  iter: iterator(): T
template items*[T](f: Filter[T]): T =
  f.iter()

iterator enumerate*[T](x: Iterable[T]): (int, T) =
  var i = 0
  for v in x:
    yield (i, v)
    i.inc


template listImpl(iter, result){.used.} =
  when compiles(iter.len):
    result = newSeq[T](iter.len)
    for i, v in enumerate(iter):
      result[i] = v
  else:
    for i in iter:
      result.add i


when defined(js):
  #[ XXX: a workaround, at least support some types
   when for js:
 nim compiler will complain about `for i in iter`'s `i` ,
 saying: internal error: expr(nkBracketExpr, tyUserTypeClassInst) ]#
  func list*[T](arr: openArray[T]): seq[T] =
    result = newSeq[T](arr.len)
    for i,v in enumerate(arr):
      result[i] = v
  proc list*[T](iter: not openArray[T] and Iterable[T]): seq[T] = 
    #listImpl iter, result
    # XXX: Code above makes compiler error:
    # `internal error: genTypeInfo(tyInferred)`
    for i in iter:
      result.add i
else:
  # it has side effects as it calls `items`
  proc list*[T](iter: Iterable[T]): seq[T] =
    listImpl iter, result


when defined(js):
  func filter*[T](comp: NoneType | proc(arg: T): bool, iter: Iterable[T]): Filter[T]{.error: """
Closure iterator is not supported for JS (Filter is impl via lambda iterator)
""".} # TODO: impl by other methods & when solved, update tests in `tmisc.nim`
else:
  func filter*[T](comp: proc(arg: T): bool, iter: Iterable[T]): Filter[T] =
    ## Python-like filter(fun, iter)
    runnableExamples:
      proc isAnswer(arg: string): bool =
        return arg in ["yes", "no", "maybe"]

      let values = @["yes", "no", "maybe", "somestr", "other", "maybe"]
      let filtered = filter(isAnswer, values)
      doAssert list(filtered) == @["yes", "no", "maybe", "maybe"]

    var it =
      iterator(): T =
        for item in iter:
          if comp(item):
            yield item
    Filter[T](iter: it)

  func filter*[T](arg: NoneType, iter: Iterable[T]): Filter[T] =
    ## Python-like filter(None, iter)
    runnableExamples:
      let values = @["", "", "", "yes", "no", "why"]
      let filtered = list(filter(None, values))
      doAssert filtered == @["yes", "no", "why"]

    result = filter[T](toBool, iter)

