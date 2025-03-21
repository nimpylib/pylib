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
import ../private/iterGen
import ./iters/[mapMacro, zipMacro]
import ./iter_next
import ../noneType
export noneType.None
export iter, next

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

template genInitor(funcName, Type){.dirty.} =
  ## used for macro
  func funcName[T](iter: iterator (): T): Type[T]{.inline.} = Type[T](iter: iter)

genInitor initMap, Map

macro map*(function: proc, iterable: typed, iterables: varargs[typed]): Map =
  ## .. note:: unlike Python, if arguments number does not fit `function`,
  ##   instead of runtime error compile-time error occurs, in which
  ##   a generated temporary name `gen_iter_res` will be seen
  let its = nnkBracket.newTree(iterable)
  iterables.copyChildrenTo its
  newCall(bindSym"initMap", mapIterBodyImpl(function, its, ident"gen_iter_res"))

type Zip[T] = object
  iter: iterator (): T
makeIterable Zip
genInitor initZip, Zip

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

iterator zip*[A, B](it1: Iterable[A], it2: Iterable[B], strict = false): (A, B){.genIter.} =
  template handleBound(ordLonger) =
    if strict: raiseZipBound ordLonger
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
        if not s2: raiseZipBound 2
        if not s1: raiseZipBound 1
      break

template onlyDefinedWhen(cond: static[bool]; body): untyped =
  when cond: body

macro zip*(iterables_or_strict: varargs[untyped]): Zip{.
    onlyDefinedWhen(not defined(pylibDisableMoreArgsZip)).} =
  ## `zip(*args, strict=False)`
  ## 
  ## ------
  ## 
  ## To support its similarity with Python's `zip` function signature,
  ## this macro signature has to be `varargs[untyped]`.
  ## 
  ## So it's designed to be undefined
  ## when `pylibDisableMoreArgsZip` is defined.
  let last = iterables_or_strict.last
  var nIt = iterables_or_strict.len
  let strict =
    #if last.getType.typeKind == ntyBool:
    if last.kind == nnkExprEqExpr:
      let keyId = last[0].strVal
      if keyId != "strict":
        error "TypeError: zip() got an unexpected keyword argument '" &
          keyId & "'."
      nIt.dec
      last[1]
    else: newLit false

  result = newCall(bindSym"initZip",
    zipIterbodyImpl(iterables_or_strict[0..<nIt], strict)
  )
