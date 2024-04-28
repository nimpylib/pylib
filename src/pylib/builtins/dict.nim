
import std/tables
import std/macros
from ../collections_abc import Iterable

type 
  TableLikeObj* = Table or OrderedTable or CountTable
  TableLikeRef* = TableRef or OrderedTableRef or CountTableRef
  TableLike* = TableLikeObj or TableLikeRef

# Impl begin

type
  PyDict*[K, V] = OrderedTableRef[K, V]

template newPyDictImpl[K, V](x: varargs): untyped =
  newOrderedTable[K, V](x)

func toPyDict*[K, V](x: openArray[(K, V)]): PyDict[K, V] =
  result = newPyDictImpl[K, V](x)
  
func toPyDict*[K, V](x:
  not openArray[(K, V)] and Iterable[(K, V)]): PyDict[K, V] =
  result = newPyDictImpl[K, V]()
  for k, v in x:
    result[k] = v

macro exportTables(syms: varargs[untyped]) =
  result = newNimNode nnkExportStmt
  for sym in syms:
    result.add newDotExpr(ident"tables", sym)
exportTables `$`, `len`, `[]`, `[]=`, `==`, clear, contains, keys, values

iterator items*[K, V](self: PyDict[K, V]): (K, V) =
  for t in self.pairs:
    yield t

func copy*[K, V](self: PyDict[K, V]): PyDict[K, V] =
  result = newPyDictImpl[K, V](len(self))
  for k, v in self.items():
    result[k] = v
  
func setdefault*[K, V](self: PyDict[K, V], key: K, default = V.default) =
  ## .. warning:: `default` defaults to `V.default` instead of `None`
  if key in self:
    return self[key]
  self[key] = default
  return default

func get*[K, V](self: PyDict[K ,V], key: K): V = self[key]
func get*[K, V](self: PyDict[K ,V], key: V, default: V): V = self.getOrDefault(key, default)
func pop*[K, V](self: PyDict[K, V], key: K): V = 
  if not self.pop(key, result):
    raise newException(KeyError, $key)
func pop*[K, V](self: PyDict[K, V], key: K, default: V): V = 
  if not self.pop(key, result):
    result = default

func popitem*[K, V](self: PyDict[K, V]): (K, V) =
  result[0] = self.keys()()
  discard self.pop(result[0], result[1])

func emptyPyDict*[K, V](): PyDict[K, V] = newPyDictImpl[K, V]([])

template PyDictProc: NimNode = ident "toPyDict"

# Impl end

proc parseKeyValues(kwargs: NimNode|seq[NimNode]): NimNode =
  # k=v,... -> [("k", v),...]
  when kwargs is NimNode:
    expectKind kwargs, nnkArgList
  result = newNimNode nnkBracket
  for kw in kwargs:
    expectKind(kw, nnkExprEqExpr)
    let (k, v) = (kw[0], kw[1])
    result.add newTree(nnkTupleConstr, newLit $k, v)

proc dictByKw(kwargs: NimNode): NimNode =
  let arr = parseKeyValues kwargs
  result = newCall(PyDictProc, arr)

proc dictByIterKw(iter: NimNode; kwargs: seq[NimNode]): NimNode =
  let arr = parseKeyValues kwargs
  let lhs = newCall(PyDictProc, arr)
  let rhs = newCall(PyDictProc, iter)
  result = infix(lhs, "|", rhs)

macro dict*(kwargs: varargs[untyped]): PyDict =
  case kwargs.len
  of 0:
    # Can't we get generic args?
    error "use emptyPyDict"  # TODO: support it
  of 1:
    let arg = kwargs[0]
    result =
      if arg.kind == nnkExprEqExpr:
        dictByKw kwargs
      else:
        newCall(PyDictProc, arg)
  else:
    let first = kwargs[0]
    result =
      if first.kind == nnkExprEqExpr:
        dictByKw kwargs
      else:
        dictByIterKw(first, kwargs[1..^1])

macro update*(self: PyDict, args: varargs[untyped]) =
  ## `d.update(iterable, **kw)` or
  ## `d.update(**kw)`
  if args.len == 0:  # `d.update()`
    return newEmptyNode()
  template setKV(kv): NimNode =
    newCall("[]=", self, newLit $kv[0], kv[1])
  let first = args[0]
  let kw1st = first.kind == nnkExprEqExpr
  let kwStart = if kw1st: 0 else: 1
  if not kw1st:
    # first shall be iterable
    result = quote do:
      for t in `first`:
        `self`[t[0]] = t[1]
  else:
    result = newStmtList()
    for kw in args[kwStart..^1]:
      expectKind kw, nnkExprEqExpr
      result.add setKV kw

func `|`*[A, B: TableLike](a: A, b: B): A =
  ## Python-like merge dict operator `print({"a":1} | {"b":2})`,
  ## a new dict is created from `a` and `b`, keys in the second 
  ## operand override keys in the first operand 
  runnableExamples:
    import std/tables

    let d = {"spam": "1", "eggs": "2", "cheese": "3"}.toTable
    let e = {"cheese": "cheddar", "aardvark": "Ethel"}.toTable
    doAssert d | e == {"eggs": "2", "spam": "1", "cheese": "cheddar", "aardvark": "Ethel"}.toTable
    doAssert e | d == {"eggs": "2", "spam": "1", "cheese": "3", "aardvark": "Ethel"}.toTable

    let x = {"a": "0", "b": "1"}.toOrderedTable
    let y = {"c": "2", "b": "1"}.toOrderedTable
    doAssert x | y == {"a": "0", "b": "1", "c": "2"}.toOrderedTable

    let z = {"a": "0", "b": "1"}.toCountTable
    let v = {"c": "2", "b": "1"}.toCountTable
    doAssert z | v  == {"a": "0", "b": "1", "c": "2"}.toCountTable
  
  when A is ref|ptr:
    new result
  for key, val in a.pairs:
    result[key] = val
  
  for key, val in b.pairs:
    result[key] = val

# TableRef and similar don't need a "var" to be modified
proc `|=`*[A: TableLikeRef, B: TableLike](a: A, b: B) = 
  ## Python-like in-place dict update operator.
  ## `b` is added into `a`, keys in `b` override same keys from `a`
  runnableExamples:
    import std/tables

    let d = {"spam": "1", "eggs": "2", "cheese": "3"}.newTable
    let e = {"cheese": "cheddar", "aardvark": "Ethel"}.newTable
    d |= e
    doAssert d == {"spam": "1", "eggs": "2", "aardvark": "Ethel", "cheese": "cheddar"}.newTable
  
  for key, val in b.pairs:
    a[key] = val

# Table and similar however need it
func `|=`*[A: TableLikeObj, B: TableLike](a: var A, b: B) = 
  ## Python-like in-place dict update operator.
  ## `b` is added into `a`, keys in `b` override same keys from `a`
  runnableExamples:
    import std/tables

    var d = {"spam": "1", "eggs": "2", "cheese": "3"}.toTable
    let e = {"cheese": "cheddar", "aardvark": "Ethel"}.newTable
    d |= e
    doAssert d == {"spam": "1", "eggs": "2", "aardvark": "Ethel", "cheese": "cheddar"}.toTable

  for key, val in b.pairs:
    a[key] = val
