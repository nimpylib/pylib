
from std/sequtils import toSeq
import ./n_itertools
import ../builtins/list
import ../private/iterGen
import ../collections_abc

template asgnToSeq[T](sequ; it: Iterable[T]){.dirty.} =
  when compiles(it.toSeq):
    sequ = it.toSeq
  else:
    when compiles(iterable.len):
      sequ = newSeqOfCap(iterable.len)
    for i in iterable:
      sequ.add i

iterator combinations*[T](iterable: Iterable[T], r: int): PyList[T]{.genIter.} =
  ## XXX: yield list instead of tuple
  var sequ: seq[T]
  asgnToSeq sequ, iterable
  for s in n_itertools.combinations(sequ, r):
    yield newPyList(s)

iterator accumulate*[T](iterable: Iterable[T],
    binop: BinOp[T] = add[T]; inital = mayZeroDefault(T)): T{.genIter.} =
  var sequ: seq[T]
  asgnToSeq sequ, iterable
  n_itertools.accumulate(sequ, binop, inital)

