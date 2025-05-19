
import std/typetraits
import ../pystring/strimpl
type
  list*[T] = ref object
    data: seq[T]
  # shall be a distinct type of seq, as some routiues has different signature
  #  for example, `seq[T].insert(T, int)` and `list[T].insert(int, T)`
type PyList*[T] = list[T]


converter asSeq*[T](self: PyList[T]): seq[T] = self.data
converter asSeq*[T](self: var PyList[T]): var seq[T] = self.data

func `@`*[T](ls: PyList[T]): seq[T] = ls.data
func setLen*(self: PyList, len: Natural) =
  ## EXT.
  ## unstable. only works for simple types
  # used by Lib/array frombytes
  system.setLen(self.data, len)

func repr*[T: set|string|openArray](self: PyList[T]): string =
  system.repr self.data.toOpenArray(0, len(self)-1)
# `repr` defined for other elements' type is in about L160

func newPyList*[T](s: sink seq[T]): PyList[T]{.inline.} = PyList[T](data: s)
func newPyList*[T](a: sink openArray[T]): PyList[T]{.inline.} = PyList[T](data: @a)

static: assert PyStr.distinctBase is string, "current impl of newPyListOfStr assumes PyStr is distinct string"
func newPyListOfStr*(a: PyList[string]): PyList[PyStr]{.inline.} = cast[PyList[PyStr]](a)
func newPyListOfStr*(a: openArray[string]): PyList[PyStr]{.inline.} = newPyListOfStr(newPyList a)

when true:
  #[ XXX: NIM-BUG: as of 2.3.1, without following, compile for a module that imports both test_datetime and test_array
  crashes with C compiler error:

  @m..@s..@sbuiltins@slist_decl.nim.c:1250:15: error: incompatible types when assigning to type ‘tySequence__MkqYvXY8u0yYYH9auGhczBw’ from type ‘tySequence__lBgZ7a89beZGYPl8PiANMTA’
  1250 | (*T1_).data = at___test95datetime_u2909(a_p0, a_p0Len_0);
  ]#
  template gen(T){.dirty.} =
    func newPyList*(a: sink openArray[T]): PyList[T]{.inline.} = PyList[T](data: @a)
  gen int
  gen float
  gen char

func newPyList*[T](len=0): PyList[T]{.inline.} = newPyList newSeq[T](len)
func newPyListOfCap*[T](cap=0): PyList[T]{.inline.} =
  newPyList newSeqOfCap[T](cap)

iterator items*[T](self: PyList[T]): T =
  for i in self.data: yield i

iterator mitems*[T](self: PyList[T]): var T =
  ## EXT.
  for i in self.data.mitems: yield i

iterator pairs*[T](self: PyList[T]): (int, T) =
  ## EXT. Nim's auto-enumerate
  for (i, e) in self.data.pairs: yield (i, e)

template getPtr[T](self: seq[T], i: int): ptr T =
  when NimMajor == 1:
    self[i].unsafeAddr
  else:
    self[i].addr

func getPtr*[T](self: sink PyList[T], i: Natural|BackwardsIndex): ptr T{.inline.} =
  ## EXT.
  ## unstable.
  ## used by Lib/array `frombytes` and `tobytes`.
  self.data.getPtr i


template checkLenientOps*(A, B) =
  ## inner. unstable
  when defined(pylibNoLenient):
    when A is_not B:
      {.error: "once pylibNoLenient is defined, " &
        " mixin ops between types is forbidden".}

template cmpBody(op, a, b) =
  bind checkLenientOps
  checkLenientOps A, B
  const opS = astToStr(op)
  # Shortcut: if the lengths differ, the arrays differ
  when opS == "==":
    if a.len != b.len: return
  elif opS == "!=":
    if a.len != b.len: return true

  for i, e in a:
    if e != b[i]:
      # We have an item that differs.
      result = op(e, b[i])
      return
  # No more items to compare -- compare sizes
  result = op(a.len, b.len)

func `<=`[A, B](a: openarray[A], b: openarray[B]): bool = cmpBody `<=`, a, b
func `<` [A, B](a: openarray[A], b: openarray[B]): bool = cmpBody `<`,  a, b

template genMixCmp(op){.dirty.} =
  func op*[A, B](self: PyList[A], o: PyList[B]): bool{.inline.} =
    bind op
    op self.asSeq, o.asSeq
  func op*[A, B](self: PyList[A], o: openArray[B]): bool{.inline.} =
    bind op
    op self.asSeq, o
  template op*[A, B](o: openArray[A], self: PyList[B]): bool =
    bind op
    op(self, o)

genMixCmp `==`
genMixCmp `<=`
genMixCmp `<`
