
import std/tables
import std/macros
from ../collections_abc import Iterable

type 
  TableLikeObj* = Table or OrderedTable or CountTable
  TableLikeRef* = TableRef or OrderedTableRef or CountTableRef
  TableLike* = TableLikeObj or TableLikeRef

# Impl begin

type
  PyDict*[K, V] = distinct OrderedTableRef[K, V]
  PyDictView* = object of RootObj ## .. warning:: currently `mapping` attr
                                  ## is dict itself, i.e. modifiable
  PyDictKeyView*[T] = object of PyDictView
    mapping*: PyDict[T, auto]
  PyDictValueView*[T] = object of PyDictView
    mapping*: PyDict[auto, T]
  PyDictItemView*[K, V] = object of PyDictView
    mapping*: PyDict[K, V]
  SomeSinglePyDictView*[T] = PyDictValueView[T]|PyDictKeyView[T]
  SomePyDictView* = PyDictKeyView | PyDictValueView | PyDictItemView


template toNimTable(self: PyDict): OrderedTableRef = OrderedTableRef(self)
proc contains*[A, B](t: PyDict[A, B], key: A): bool = contains(t.toNimTable, key)
proc `[]`*[A, B](t: var PyDict[A, B], key: A) = `[]`(t.toNimTable, key)
proc `[]=`*[A, B](t: var PyDict[A, B], key: A, val: sink B) =
  `[]=`(t.toNimTable, key, val)
proc getOrDefault[A, B](t: PyDict[A, B], key: A): B =
  ## inner. used to impl get(key, default)
  t.toNimTable.getOrDefault key

using self: PyDict

template strIterImpl(view, strProc;
    start, stop): string =
  let le = view.len
  var result = newStringOfCap(2+3*le)
  result.add start
  var i = 0
  for v in view:
    if i == le - 1:
      result.add v.strProc
      break
    result.add v.strProc & ", "
  result.add stop

template strByView(k): string =
  mixin repr
  k.repr & ": " & view[k].repr

template repr*(self: PyDict): string =
  bind strIterImpl
  mixin repr
  strIterImpl self, strByView, '{', '}'

template `$`*(self: PyDict): string =
  bind repr
  repr self

proc len*(self): int =
  ## dict.__len__
  self.toNimTable.len

proc `==`*[A, B](self, other: PyDict[A, B]): bool = self.toNimTable == other.toNimTable

proc clear*(self) = self.toNimTable.clear

proc len*(view: SomePyDictView): int = view.mapping.len
template iter*(view: SomePyDictView): untyped = view.mapping.iter
template items*(view: SomePyDictView): untyped = view.iter
func contains*[T](t: PyDictKeyView[T], x: T): bool = contains(t.mapping, x)
func contains*[T](t: PyDictValueView[T], x: T): bool = 
  for k in t.mapping:
    if t.mapping[k] == x: return true
func contains*[K, V](t: PyDictItemView[K, V], x: (K, V)): bool = 
  if x[0] in t.mapping:
    return x[1] == t.mapping[x[0]]

template genRepr(typ, prefix) =
  template repr*(view: typ): string =
    bind strIterImpl
    mixin repr
    strIterImpl view, repr, prefix & "([", "])"
  template `$`*(view: typ): string =
    bind repr
    repr view

genRepr PyDictKeyView,   "dict_keys"
genRepr PyDictValueView, "dict_values"
genRepr PyDictItemView,  "dict_items"


iterator keys*[K, V](self: PyDict[K ,V]): K =
  for i in self.toNimTable: yield i

iterator iter*[K, V](self: PyDict[K ,V]): K =
  ## .. warning:: Nim's for stmt calls `items` implicitly, instead of iter
  ## so beware to always write `iter` for dict in for loop
  runnableExamples:
    let d = dict(a=1)
    for i in iter(d):
      assert i == "a"
    for i in d:
      assert i == ("a", 1)
  
  for i in self.keys: yield i


iterator values*[K, V](self: PyDict[K ,V]): V =
  for i in self.toNimTable.values: yield i

iterator items*[K, V](self: PyDict[K ,V]): (K, V) =
  for i in self.toNimTable.pairs: yield i

func keys*[K, V](self: PyDict[K ,V]): PyDictKeyView[K] = result.mapping = self
func values*[K, V](self: PyDict[K ,V]): PyDictValueView[V] = result.mapping = self
func items*[K, V](self: PyDict[K ,V]): PyDictItemView[K, V] = result.mapping = self

template newPyDictImpl[K, V](x: varargs): untyped =
  ## zero or one arg
  ## shall support `[]`, `{k:v}`, `@[(k, v),...]`
  PyDict newOrderedTable[K, V](x)

func toPyDict*[K, V](x: openArray[(K, V)]): PyDict[K, V] =
  # NOTE: in Nim, `{k:v, ...}` is of `array[(type(k), type(v))]`
  result = newPyDictImpl[K, V](x)
  
func toPyDict*[K, V](x:
  not openArray[(K, V)] and Iterable[(K, V)]): PyDict[K, V] =
  result = newPyDictImpl[K, V]()
  for k, v in x:
    result[k] = v

func copy*[K, V](self: PyDict[K, V]): PyDict[K, V] =
  result = newPyDictImpl[K, V](len(self))
  for k, v in self.items():
    result[k] = v

# as PyDict is of `ref` type, no need to use `var PyDict` for param type

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

proc delitem*[K, V](self: PyDict[K, V], k: K) =
  ## pysugar expect such a proc to hook `del d[k]`
  self.toNimTable.del k

func emptyPyDict*[K, V](): PyDict[K, V] = newPyDictImpl[K, V]([])

template PyDictProc: NimNode = ident "toPyDict" # the proc must be exported

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

# Why cannot...: func dict*[K, V](): PyDict[K, V] = emptyPyDict[K, V]()
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
