## builtins.iter

import ../collections_abc

#iterator items*[T](it: PyIterable[T]): T = for i in it.iter: yield i

type
  StopIteration* = object of CatchableError
  PyIterator*[T] = ref object
    iter: iterator (): T

func newPyIterator*[T](it: iterator (): T): PyIterator[T] =
  ## init with a Nim iterator
  PyIterator[T](iter: it)

func iter*[T](x: Iterable[T]): PyIterator[T] =
  when x.items is "closure":
    result = newPyIterator[T](x.items)
  else:
    result = newPyIterator[T](iterator (): T =
      for i in x:
        yield i
    )

func iter*[T](x: Iterator[T]): PyIterator[T] =
  result = newPyIterator[T](iterator (): T =
    while true:
      try:
        yield x.next
      except StopIteration:
        break
    )

iterator items*[T](self: PyIterator[T]): T =
  for i in self.iter():
    yield i

proc next*[T](self: PyIterator[T]): T =
  # see manual, sysmte.finished shall validate after a value is getten from iterator.
  result = self.iter()
  if self.iter.finished():
    raise newException(StopIteration, "iterator stop")
