


from ./collections_abc import Iterable, Sized
from ./pybool import toBool
import ./noneType
export noneType.None

import std/macros

func capital(s: string): string =
  ## assume s[0].isLowerAscii()
  char(s[0].ord - 32) & s.substr(1)

template makeIterable(Typ) =
  template items*(x: Typ): untyped =
    x.iter()

macro genIter(def) =
  ## Generates code of non-reentrant iterable,
  ## according to an iterator.
  expectKind def, nnkIteratorDef
  let nameAstr = def[0]
  expectKind nameAstr, nnkPostfix
  let name = nameAstr[1]
  let
    genericParams = def[2]
    r_params = def[3]
    otherPragmas = def[4]
    body = def.body  # def[5]

  let rtype = r_params[0]

  let sName = name.strVal
  let typId = ident sName.capital()
  result = newStmtList()
  result.add quote do:
    when not declared(`typId`):  # XXX: allow overload/defined types
      type `typId`[T] = object
        iter: iterator(): `rtype`
      makeIterable `typId`
      
  var funcDef = newProc(nameAstr, procType=nnkFuncDef, pragmas=otherPragmas)
  funcDef[2] = genericParams
  funcDef[3] = r_params.copy()
  # genericParams[0].kind == nnkIdentDefs 
  let funcResType = genericParams[0][0]
  funcDef[3][0] = nnkBracketExpr.newTree(typId, funcResType)
  # no need to strip doc manually,
  #  as `body` is of lambda iterator.
  let funcBody = quote do:
    result.iter = iterator(): `rtype` = `body`  
  funcDef.body = funcBody
  result.add funcDef
      
  result.add def

iterator filter*[T](comp: proc(arg: T): bool, iter: Iterable[T]): T{.genIter.} =
  runnableExamples:
    proc isAnswer(arg: string): bool =
      return arg in ["yes", "no", "maybe"]

    let values = @["yes", "no", "maybe", "somestr", "other", "maybe"]
    let filtered = filter(isAnswer, values)  # invoke `proc filter`
    doAssert list(filtered) == @["yes", "no", "maybe", "maybe"]

  for item in iter:
    if comp(item):
      yield item

iterator filter*[T](comp: NoneType, iter: Iterable[T]): T{.genIter.} =
  runnableExamples:
    let values = @["", "", "", "yes", "no", "why"]
    let filtered = list(filter(None, values))  # invoke `proc filter`
    doAssert filtered == @["yes", "no", "why"]

  for item in iter:
    if toBool(item):
      yield item

iterator enumerate*[T](x: Iterable[T], start=0): (int, T){.genIter.} =
  var i = start
  for v in x:
    yield (i, v)
    i.inc

func list*[T](): seq[T] =
  runnableExamples:
    assert list[int]() == list[int]([])
  discard
  

# it has side effects as it may call `items`
proc list*[T](iter: Iterable[T]): seq[T] =
  when compiles(iter.len):
    result = newSeq[T](iter.len)
    for i, v in enumerate(iter):
      result[i] = v
  else:
    for i in iter:
      result.add i

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

