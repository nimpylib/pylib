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
import ./set_decl
export set_decl except asHashSet, incl, excl

type
  SomeSet*[H] = SomePySet[H] or HashSet[H] or OrderedSet[H] or system.set[H]

macro genpysets(defs) =
  let name = ident"pyset"
  result = newStmtList()
  for def in defs:
    var nDef = def.copyNimTree()
    nDef[0][^1] = name
    result.add(def, nDef)

genpysets:
  proc set*[H](): PySet[H] =
    newPySet initHashSet[H]()
  proc set*[H](s: HashSet[H]): PySet[H] =
    newPySet s
  proc set*[H](s: SomePySet[H]): PySet[H] = set(s.asHashSet)
  proc set*[H](arr: openArray[H]): PySet[H] = set arr.toHashSet
  proc set*[H](iterable: Iterable[H]): PySet[H] =
    result = set[H]()
    for i in iterable:
      result.incl i

proc frozenset*[H](): PyFrozenSet[H] =
  newPyFrozenSet initHashSet[H]()
proc frozenset*[H](s: HashSet[H]): PyFrozenSet[H] =
  newPyFrozenSet s
proc frozenset*[H](s: SomePySet[H]): PyFrozenSet[H] = frozenset(s.asHashSet)
proc frozenset*[H](arr: openArray[H]): PyFrozenSet[H] = frozenset arr.toHashSet
proc frozenset*[H](it: Iterable[H]): PyFrozenSet[H] =
  # NIM-BUG: 
  # sth like: when compiles(iterable.len): set[H](iterable.len) else: ..
  # causes compile error
  result = frozenset[H]()
  for i in it:
    result.incl i

# Q: Why not define as `set` or `pyset`
# A: That makes empty set impossible.
macro pysetLit*(lit): PySet =
  ## To solve: `pyset({1,2,3})` is invalid
  expectKind lit, nnkCurly
  var ls = newNimNode nnkBracket
  for i in lit:
    ls.add i
  result = newCall("pyset", ls)

template somepyset[H](S: typedesc[PySet[H]], s: typed): S = pyset[H](s)
template somepyset[H](S: typedesc[PyFrozenSet[H]], s: typed): S = frozenset[H](s)

template copy*[H; S: SomePySet[H]](self): S =
  bind somepyset; somepyset(S, self)

template doBinData(op){.dirty.} =
  proc op*[H](self, o: PySet[H]): PySet[H] =
    pyset op(self.asHashSet, o.asHashSet)
  proc op*[H](self: PyFrozenSet[H]; o: SomePySet[H]): PyFrozenSet[H] =
    frozenset op(self.asHashSet, o.asHashSet)
  proc op*[H](self: PySet[H]; o: PyFrozenSet[H]): PyFrozenSet[H] =
    frozenset op(self.asHashSet, o.asHashSet)

macro doBinDatas(syms: varargs[untyped]) =
  result = newStmtList()
  for sym in syms:
    result.add newCall(ident"doBinData", sym)

doBinDatas `-`, intersection, union, difference, symmetric_difference

const SetLitBugMsg = "When used, Nim compiler(at least 2.0.0-2.1.2) will complain:\n" & """
'Error: unhandled exception: ccgexprs.nim(1994, 9) `setType.kind == tySet`', 
Consider using `pyset` instead of set literal."""
template genBinSys(ret, op){.dirty.} =
  # XXX: see below
  proc op*[H](self: SomePySet[H], s: system.set[H]): ret{.error: SetLitBugMsg.} =
    op self, pyset(s)
  proc op*[H](s: system.set[H], self: SomePySet[H]): ret{.error: SetLitBugMsg.} = op self, s
template genBinSysBool(op) = genBinSys(bool, op)

genBinSysBool `==`
genBinSysBool `<=`
genBinSysBool `<`


template aliasBin(alias, old){.dirty.} =
  # binary op's rhs must be set too
  template alias*[H; M: SomePySet[H]; S: SomePySet[H]](
    self: M, s: S): M|S = old(self, s)

aliasBin `^`, symmetric_difference
aliasBin `&`, intersection 
aliasBin `|`, union

template boolAliasBin(alias, old){.dirty.} =
  proc alias*[H, S](self, o: SomePySet[H], s: S): bool = old(self, s)

boolAliasBin issuperset, `>=`
boolAliasBin issubset, `<=`

template fold(op){.dirty.} =
  # set.op(*others)
  proc op*[H; Self: SomePySet[H]; S: not PySet[H]](
    self: Self, s: S): Self =
    op(self, somepyset(Self, s))
  proc op*[H; Self: SomePySet[H]; S](self: Self, s1: auto, s2: auto;
      x: varargs[S]): Self =
    result = op(self, s1)
    result = op(result, s2)
    for i in x:
      result = op(result, i)

fold intersection
fold union
fold difference
fold symmetric_difference

func isdisjoint*[H, S](self: SomePySet[H], s: S): bool =
  len(self.intersection(s)) == 0

proc add*[H](self: var PySet[H], x: H) = self.incl x
proc `discard`*[H](self: var PySet[H], ele: H) =
  ## `discard` is keyword of Nim, consider use `\`discard\`` or pydiscard
  self.excl ele
proc pydiscard*[H](self: var PySet[H], ele: H) =
  ## set.discard(ele)
  self.`discard` ele

proc remove*[H](self: var PySet[H], ele: H) =
  if self.missingOrExcl ele:
    raise newException(KeyError, $ele)


template genUpdate(sysOp, op, fun){.dirty.} =
  proc op*[H; S: SomeSet[H]](self: var SomePySet[H]; s: S) = sysop self, s
  proc fun*[H; I: Iterable[H]](self: var SomePySet[H]; i: I) = sysop self, pyset(i)

genUpdate excl, `-=`, difference_update
genUpdate incl, `|=`, update

proc isec[S: SomeSet; S2: SomeSet](self: var S, s: S2) = self = self * s
genUpdate isec, `&=`, intersection_update

