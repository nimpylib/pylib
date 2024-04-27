## set and its methods.
## 
## ## set type
## `set[T]` is still for `system.set[T]`,
## with its restriction of only allowing small ordinal as elements.
## `PySet[T]` is used to minic Python's.
## 
## ## Literal
## Something like `{1,2}` shall be rewritten as `pyset([1,2])`,
## please note either `pyset((1,2))` or `pyset({1,2})` doesn't mean the same.
import std/sets
import std/macros
from ../collections_abc import Iterable

type
  PySet*[H] = HashSet[H]
  SomeSet*[H] = HashSet[H] or OrderedSet[H] or system.set[H]

func set*[H](): PySet[H] = initHashSet[H]()
func set*[H](iterable: Iterable[H]): PySet[H] =
  for i in iterable:
    result.add i
func set*[H](s: PySet[H]): PySet[H] = s
func set*[H](s: HashSet[H]): PySet[H] = s
func pyset*[T](iterable: Iterable[T]): PySet[T] =
  set[T](iterable)
template pyset*[H](): PySet[H] =
  bind set
  set[H]()
template copy*[H](self: PySet[H]): PySet[H] = pyset(self)

template genBinSys(ret, op) =
  func op*[H](self: PySet[H], s: system.set[H]): ret =
    op self, pyset(s)
  func op*[H](s: system.set[H], self: PySet[H]): ret = op self, s
template genBinSysBool(op) = genBinSys(bool, op)
  
genBinSysBool `==`
genBinSysBool `<=`
genBinSysBool `<`

macro exportSets(syms: varargs[untyped]) =
  result = newNimNode nnkExportStmt
  for sym in syms:
    result.add newDotExpr(ident"sets", sym)
exportSets `$`, `len`, `pop`, `[]`, `-`, `==`, `<`, `<=`, clear, contains, items,
  intersection, union, difference, symmetric_difference


template aliasBin(alias, old) =
  # binary op's rhs must be set too
  func alias*[H; S: SomeSet[H]](self: PySet[H], s: S): PySet[H] = old(self, s)

aliasBin `^`, symmetric_difference
aliasBin `&`, intersection 
aliasBin `|`, union

template boolAliasBin(alias, old) =
  func alias*[H, S](self: PySet[H], s: S): bool = old(self, s)

boolAliasBin issuperset, `>=`
boolAliasBin issubset, `<=`

template fold(op) =
  # set.op(*others)
  func op*[H; S: not PySet[H] and SomeSet[H]](
    self: PySet[H], s: S): PySet[H] =
    op(self, pyset[H](iterable))
  func op*[H; I: not SomeSet[H] and Iterable[H]](
    self: PySet[H], iterable: I): PySet[H] =
    op(self, pyset[H](iterable))
  func op*[H, S](self: PySet[H], s1: auto, s2: auto; x: varargs[S]): PySet[H] =
    result = op(self, s1)
    result = op(result, s2)
    for i in x:
      result = op(result, i)

fold intersection
fold union
fold difference
fold symmetric_difference

func isdisjoint*[H, S](self: PySet[H], s: S): bool =
  len(self.intersection(s)) == 0


func add*[H](self: var PySet[H], x: H) = self.incl x
func `discard`*[H](self: var PySet[H], ele: H) =
  ## `discard` is keyword of Nim, consider use `\`discard\`` or pydiscard
  self.excl ele
func pydiscard*[H](self: var PySet[H], ele: H) =
  ## set.discard(ele)
  self.`discard` ele

func remove*[H](self: var PySet[H], ele: H) =
  if self.missingOrExcl ele:
    raise newException(KeyError, $ele)


template genUpdate(sysOp, op, fun) =
  func op*[H; S: SomeSet[H]](self: var PySet[H]; s: S) = sysop self, s
  func fun*[H; I: Iterable[H]](self: var PySet[H]; i: I) = sysop self, pyset(i)

genUpdate excl, `-=`, difference_update
genUpdate incl, `|=`, update

func isec[S: SomeSet; S2: SomeSet](self: var S, s: S2) = self = self * s
genUpdate isec, `&=`, intersection_update

