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
import ./iter_next
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

#[
XXX: NIM-BUG:

If using the following approach:

```Nim
type SizedGetitem[T] = concept self
  self is Sized
  self[int] is T
templat isSizedGetitem[T](it): bool = it is SizedGetitem[T]
```
the compiler will report error for one case:

  it1 or it2 is `HashSet`

The Error:

```
Expression: it1[i]
  [1] it1: Iterable[int, Iterable]
  [2] i: int
```
One reason is that `HashSet` defines:

```Nim
  proc `[]`*[A](s: var HashSet[A], key: A): var A
```

Anyway in turn,a `it: HashSet` will be always matched as a `SizedGetitem`
but `it[0]` cannot be compiled.

That's why the following approach is used for now.

]#
#iterator zip*[A](it: Iterable[A], strict: static[bool]=false): (A){.genIter.} =

template isSizedGetitem[T](it): bool =
  it is Sized and compiles((let _ = it[0]))

func raiseBound(ordLonger: int){.inline.} =
  raise newException(ValueError, 
    "zip() argument " & $ordLonger & " is longer than argument " & $(ordLonger-1))

iterator zip*[A, B](it1: Iterable[A], it2: Iterable[B], strict: static[bool]=false): (A, B){.genIter.} =
  template handleBound(ordLonger) =
    when strict: raiseBound ordLonger
    else: break
  when it1.isSizedGetitem[:A]:
    let le = it1.len
    for i, v in enumerate(it2):
      if i == le: handleBound 2
      yield (it1[i], v)
  elif it2.isSizedGetitem[:B]:
    let le = it2.len
    for i, v in enumerate(it1):
      if i == le: handleBound 1
      yield (v, it2[i])
  else:
    var
      itor1 = iter(it1)
      itor2 = iter(it2)
    
    var res: (A,B)
    var s1, s2: bool

    while true:
      s1 = itor1.nextImpl res[0]
      s2 = itor2.nextImpl res[1]
      if s1 and s2:
        yield res
        continue
      if strict:
        if s1 and not s2: raiseBound 2
        if s2 and not s1: raiseBound 1
      break


# XXX: worthy to impl? macro zip*[T](iterables_or_strict: varargs[typed])

