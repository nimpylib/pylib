

type ClosureIter*[T] = iterator (): T
#type NimIterator*[T] = ClosureIter[T] or iterable[T]
type OpenarrayOrNimIter*[T] = openarray[T] or ClosureIter[T]

template toNimIterator*[T](x): ClosureIter[T] =
  iterator (): T =
    for i in x:
      yield i

from std/sequtils import toSeq
export toSeq

template openarray_Check*(x): bool =
  x is openarray

func dist_checkedSameLen*[T](p, q: T): int{.inline.} =
  result = len(p)
  if result != len(q):
    raise newException(ValueError,
                    "both points must have the same number of dimensions")
