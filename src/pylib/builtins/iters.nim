## Some iterable in builtins
##
## XXX: For JS backend:
## Currently due to Nim's inner buys, using of some iterable functions in this modules
## may result in `Error: ...`:
## 
## - list(...)
## - filter/map/... as func (using iterator is okey)  (solved after Nim-2.1.1)
## 
## For details, trace:
## 
## - closure iterator: https://github.com/nim-lang/Nim/issues/4695  (solved after Nim-2.1.1)
## - `concept` about `for loop`: 
##   https://github.com/nim-lang/Nim/issues/9550#issuecomment-2045173674

import ../collections_abc
from ../pybool import toBool
import ./private/iterGen
import ../noneType
export noneType.None

import std/macros

iterator filter*[T](comp: proc(arg: T): bool, iter: Iterable[T]): T{.genIter.} =
  for item in iter:
    if comp(item):
      yield item

iterator filter*[T](comp: NoneType, iter: Iterable[T]): T{.genIter.} =
  for item in iter:
    if toBool(item):
      yield item

iterator enumerate*[T](x: Iterable[T], start=0): (int, T){.genIter.} =
  var i = start
  for v in x:
    yield (i, v)
    i.inc

iterator reversed*[T](x: Sequence[T]): T{.genIter.} =
  let le = len(x)
  for i in countdown(le-1, 0):
    yield x[i]


type Map[R] = object
  iter: iterator (): R
makeIterable Map

iterator map*[T, R](function: proc (x: T): R,
  iterable: Iterable[T]): R{.genIter.} =
  for i in iterable:
    yield function(i)

#[ XXX: hard to impl, may impl via macro
iterator map*[T, R](function: proc (xs: varargs[T]): R,
  iterables: varargs[Iterable[T]]): R{.genIter.}
]#

type Zip[T] = object
  iter: iterator (): T
makeIterable Zip

type SizedGetitem = concept self
  self is Sized
  self[int]

iterator zip*[A, B](it1: Iterable[A], it2: Iterable[B], strict: static[bool]=false): (A, B){.genIter.} =
  template handleBound(ordLonger: int) =
    when strict: raise newException(ValueError, 
      "zip() argument " & $ordLonger & " is longer than argument " & $(ordLonger-1))
    else: break
  when it1 is SizedGetitem:
    let le = it1.len
    for i, v in enumerate(it2):
      if i == le: handleBound 2
      yield (it1[i], v)
  elif it2 is SizedGetitem:
    let le = it2.len
    for i, v in enumerate(it1):
      if i == le: handleBound 1
      yield (v, it2[i])
  else:
    {.error: "this kind of `zip` is not implemented yet".}

# XXX: worthy to impl? macro zip*[T](iterables: varargs[typed], strict=false)

