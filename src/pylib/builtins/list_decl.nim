

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

func newPyList*[T](s: seq[T]): PyList[T] =
  result = PyList[T](data: s)
func newPyList*[T](a: openArray[T]): PyList[T] =
  result = PyList[T](data: @a)
func newPyList*[T](len=0): PyList[T] = newPyList newSeq[T](len)
func newPyListOfCap*[T](cap=0): PyList[T] = newPyList newSeqOfCap[T](cap)

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

func getPtr*[T](self: var PyList[T], i: Natural|BackwardsIndex): ptr T =
  ## EXT.
  ## unstable.
  ## used by Lib/array `frombytes` and `tobytes`.
  self.data.getPtr i

template cmpBody(op, a, b) =
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

func `<=`[T](a, b: openarray[T]): bool = cmpBody `<=`, a, b
func `<`[T](a, b: openarray[T]): bool =  cmpBody `<`,  a, b

template genMixCmp(op){.dirty.} =
  func op*[T](self, o: PyList[T]): bool = op self.asSeq, o.asSeq
  func op*[T](self: PyList[T], o: seq[T]): bool = self.asSeq op o
  func op*[T](self: PyList[T], o: openArray[T]): bool = self.asSeq op @o
  template op*[T](o: seq[T]|openArray[T], self: PyList[T]): bool =
    bind op
    op(self, o)

genMixCmp `==`
genMixCmp `<=`
genMixCmp `<`
