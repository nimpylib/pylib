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
  PySet*[H] = ref object
    data: HashSet[H]
  SomeSet*[H] = PySet[H] or HashSet[H] or OrderedSet[H] or system.set[H]

converter toHashSet[H](self: PySet[H]): HashSet[H] = self.data
converter toHashSet[H](self: var PySet[H]): var HashSet[H] = self.data

proc incl[H](self: var PySet[H], x: H) = self.data.incl x
proc excl[H](self: var PySet[H], x: H) = self.data.excl x

macro genpysets(defs) =
  let name = ident"pyset"
  result = newStmtList()
  for def in defs:
    var nDef = def.copyNimTree()
    nDef[0][^1] = name
    result.add(def, nDef)

genpysets:
  proc set*[H](): PySet[H] =
    new result
    result.data = initHashSet[H]()
  proc set*[H](s: HashSet[H]): PySet[H] =
    new result
    result.data = s
  proc set*[H](s: PySet[H]): PySet[H] = set(s.data)
  proc set*[H](arr: openarray[H]): PySet[H] = set arr.toHashSet
  proc set*[H](iterable: Iterable[H]): PySet[H] =
    result = set[H]()
    for i in iterable:
      result.add i

# Q: Why not define as `set` or `pyset`
# A: That makes empty set impossible.
macro pysetLit*(lit): PySet =
  ## To solve: `pyset({1,2,3})` is invalid
  expectKind lit, nnkCurly
  var ls = newNimNode nnkBracket
  for i in lit:
    ls.add i
  result = newCall("pyset", ls)

template copy*[H](self: PySet[H]): PySet[H] = pyset(self)

func len*(self: PySet): int = self.data.len
func `$`*(self: PySet): string = $self.data
func repr*(self: Pyset): string = $self.data
proc clear*(self: var PySet): int = self.data.clear()
func `==`*(self, o: PySet): int = self.data == o.data
func `<=`*(self, o: PySet): int = self.data <= o.data
func `<`*(self, o: PySet): int = self.data < o.data
func contains*[H](self: PySet[H], x: H): bool = self.data.contains x
proc pop*[H](self: var PySet[H]): H{.discardable.} = self.data.pop()
iterator items*[H](self: PySet[H]): H =
  for i in self.data: yield i
export sets.items

template doBinData(op){.dirty.} =
  proc op*[H](self, o: PySet[H]): PySet[H] =
    pyset op(self.data, o.data)

macro doBinDatas(syms: varargs[untyped]) =
  result = newStmtList()
  for sym in syms:
    result.add newCall(ident"doBinData", sym)

doBinDatas `-`, intersection, union, difference, symmetric_difference

const SetLitBugMsg = "When used, Nim compiler(at least 2.0.0-2.1.2) will complain:\n" & """
'Error: unhandled exception: ccgexprs.nim(1994, 9) `setType.kind == tySet`', 
Consider use `pyset` instead of set literal."""
template genBinSys(ret, op) =
  # XXX: see below
  proc op*[H](self: PySet[H], s: system.set[H]): ret{.error: SetLitBugMsg.} =
    op self, pyset(s)
  proc op*[H](s: system.set[H], self: PySet[H]): ret{.error: SetLitBugMsg.} = op self, s
template genBinSysBool(op) = genBinSys(bool, op)
  
genBinSysBool `==`
genBinSysBool `<=`
genBinSysBool `<`


template aliasBin(alias, old) =
  # binary op's rhs must be set too
  proc alias*[H; S: SomeSet[H]](self: PySet[H], s: S): PySet[H] = old(self, s)

aliasBin `^`, symmetric_difference
aliasBin `&`, intersection 
aliasBin `|`, union

template boolAliasBin(alias, old) =
  proc alias*[H, S](self: PySet[H], s: S): bool = old(self, s)

boolAliasBin issuperset, `>=`
boolAliasBin issubset, `<=`

template fold(op){.dirty.} =
  # set.op(*others)
  proc op*[H; S: not PySet[H]](
    self: PySet[H], s: S): PySet[H] =
    op(self, pyset[H](s))
  proc op*[H, S](self: PySet[H], s1: auto, s2: auto; x: varargs[S]): PySet[H] =
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
  proc op*[H; S: SomeSet[H]](self: var PySet[H]; s: S) = sysop self, s
  proc fun*[H; I: Iterable[H]](self: var PySet[H]; i: I) = sysop self, pyset(i)

genUpdate excl, `-=`, difference_update
genUpdate incl, `|=`, update

proc isec[S: SomeSet; S2: SomeSet](self: var S, s: S2) = self = self * s
genUpdate isec, `&=`, intersection_update

