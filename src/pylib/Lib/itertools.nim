
import ./nitertools
import ../builtins/list
import ../collections_abc

iterator combinations*[T](iterable: Iterable[T], r: int): PyList[T] =
  ## XXX: yield list instead of tuple
  var sequ: seq[T]
  when compiles(iterable.len):
    sequ = newSeqOfCap(iterable.len)
  for i in iterable:
    sequ.add i
  for s in combinationsSeq(sequ, r):
    yield newPyList(s)

type
  combinationsobject[T] = ref object
    iter: iterator (): PyList[T]

iterator items*[T](self: combinationsobject[T]): PyList[T] =
  for i in self.iter: yield i

func combinations*[T](iterable: Iterable[T], r: int): combinationsobject[T] =
  new result
  result.iter = iterator () =
    for i in combinations(iterable, r): yield i

