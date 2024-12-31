## builtins.iter

import ../collections_abc
import std/options

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

proc nextImpl*[T](self: PyIterator[T]): Option[T]{.inline.} =
  ## EXT. Get rid of exception for faster iteration.
  result = some self.iter()
  if self.iter.finished(): result = none(T)

proc nextImpl*[T](self: PyIterator[T], res: var T): bool{.inline.} =
  ## EXT. Get rid of exception for faster iteration.
  res = self.iter()
  not self.iter.finished()

proc next*[T](self: PyIterator[T]): T =
  # see manual, sysmte.finished shall validate after a value is getten from iterator.
  if not self.nextImpl result:
    raise newException(StopIteration, "iterator stop")
