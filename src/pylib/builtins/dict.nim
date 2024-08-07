
import std/tables
import std/macros
import ../collections_abc
import ./iter_next
import ../pystring/strimpl
import ./dict_decl
import ./private/strIter

export dict, PyDict
export emptyPyDict

type
  PyDictView* = object of RootObj ## .. warning:: currently `mapping` attr
                                  ##   is dict itself, i.e. modifiable
  PyDictKeyView*[T] = object of PyDictView
    mapping*: PyDict[T, auto]
  PyDictValueView*[T] = object of PyDictView
    mapping*: PyDict[auto, T]
  PyDictItemView*[K, V] = object of PyDictView
    mapping*: PyDict[K, V]
  SomeSinglePyDictView*[T] = PyDictValueView[T]|PyDictKeyView[T]
  SomePyDictView* = PyDictKeyView | PyDictValueView | PyDictItemView


proc contains*[A, B](t: PyDict[A, B], key: A): bool = contains(t.toNimTable, key)
proc `[]`*[A, B](t: PyDict[A, B], key: A): B = `[]`(t.toNimTable, key)
proc `[]=`*[A, B](t: PyDict[A, B], key: A, val: sink B) =
  `[]=`(t.toNimTable, key, val)

using self: PyDict

template repr*(self: PyDict): string{.dirty.} =
  bind strIterImpl
  mixin repr
  template strBy(d; k): string{.dirty.} =
    k.repr & ": " & d[k].repr
  strIterImpl self, strBy, '{', '}'

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
  for v in t.mapping.values():
    if v == x: return true
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
  for i in self.toNimTable.keys(): yield i

iterator iter*[K, V](self: PyDict[K ,V]): K =
  ## .. warning:: Nim's for stmt calls `items` implicitly, instead of iter
  ##   so beware to always write `iter` for dict in for loop
  runnableExamples:
    let d = dict(a=1)
    for i in iter(d):
      assert i == "a"
    for i in d:
      assert i[0] == "a" and i[1] == 1
  
  for i in self.keys(): yield i

func iter*[K, V](self: PyDict[K, V]): PyIterator[K] =
  newPyIterator[K](iterator (): K =
    for k in self.keys(): yield k)

iterator values*[K, V](self: PyDict[K ,V]): V =
  for i in self.toNimTable.values(): yield i

iterator items*[K, V](self: PyDict[K ,V]): (K, V) =
  for i in self.toNimTable.pairs(): yield i

func keys*[K, V](self: PyDict[K ,V]): PyDictKeyView[K] = result.mapping = self
func values*[K, V](self: PyDict[K ,V]): PyDictValueView[V] = result.mapping = self
func items*[K, V](self: PyDict[K ,V]): PyDictItemView[K, V] = result.mapping = self

func toPyDict*[K, V](x: openArray[(K, V)]): PyDict[K, V] =
  # NOTE: in Nim, `{k:v, ...}` is of `array[(type(k), type(v))]`
  result = newPyDictImpl[K, V](x)
  
func toPyDict*[K, V](x:
  not openArray[(K, V)] and Iterable[(K, V)]): PyDict[K, V] =
  result = newPyDictImpl[K, V]()
  for (k, v) in x:
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
func get*[K, V](self: PyDict[K ,V], key: K, default: V): V = self.getOrDefault(key, default)
func pop*[K, V](self: PyDict[K, V], key: K): V = 
  if not self.pop(key, result):
    raise newException(KeyError, $key)
func pop*[K, V](self: PyDict[K, V], key: K, default: V): V = 
  if not self.toNimTable.pop(key, result):
    result = default

func popitem*[K, V](self: PyDict[K, V]): (K, V) =
  ## .. warning:: this is currently LILO instead of LIFO
  for i in self.toNimTable.keys():
    result[0] = i
    break
  discard self.pop(result[0], result[1])

proc delitem*[K, V](self: PyDict[K, V], k: K) =
  ## pysugar expect such a proc to hook `del d[k]`
  self.toNimTable.del k


template PyDictProc: NimNode = ident "toPyDict" # the proc must be exported


proc parseKeyValues(kwargs: NimNode|seq[NimNode]): NimNode =
  # k=v,... -> [("k", v),...]
  when kwargs is NimNode:
    expectKind kwargs, nnkArgList
  result = newNimNode nnkBracket
  for kw in kwargs:
    expectKind(kw, nnkExprEqExpr)
    let (k, v) = (kw[0], kw[1])
    result.add newTree(nnkTupleConstr, newCall(bindSym"str", newLit $k), v)

proc dictByKw(kws: NimNode): NimNode =
  let arr = parseKeyValues kws
  result = newCall(PyDictProc, arr)

proc dictByIterKw(iter: NimNode; kwargs: NimNode|seq[NimNode]): NimNode =
  when kwargs is NimNode:
    expectKind kwargs, nnkArgList
  let lhs = newCall(PyDictProc, iter)
  let arr = parseKeyValues kwargs
  let rhs = newCall(PyDictProc, arr)
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

# if using overload, [("a", 1), ...] will be not supported
#macro update*(self: PyDict, iterable: Iterable, kws: varargs[untyped]) =
macro update*(self: PyDict, kws: varargs[untyped]) =
  ## `d.update(**kws)`
  ## `d.update(iterable, **kws)`
  if kws.len == 0:  # `d.update()`
    return newEmptyNode()
  result = newStmtList()
  let first = kws[0]
  let is1stIter = first.kind != nnkExprEqExpr
  var startKw = 0
  let setitem = bindSym"[]="
  if is1stIter:
    result.add quote do:
      when compiles(`first`.keys()):
        for k in `first`.keys():
          `setitem` `self`, k, `first`[k]
      else:
        for t in `first`:
          `setitem` `self`, t[0], t[1]
    startKw = 1
  for kv in kws[startKw..^1]:
    result.add newCall(setitem, self, newLit $kv[0], kv[1])
  
func `|`*(a, b: PyDict): PyDict =
  ## Python-like merge dict operator,
  ## a new dict is created from `a` and `b`, keys in the second 
  ## operand override keys in the first operand 
  result = a.copy()
  for key, val in b.items():
    result[key] = val

proc `|=`*(a, b: PyDict) = 
  ## Python-like in-place dict update operator.
  ## `b` is added into `a`, keys in `b` override same keys from `a`
  for key, val in b.items():
    a[key] = val
