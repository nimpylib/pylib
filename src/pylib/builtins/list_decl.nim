

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
  for i in self.data:
    yield i

iterator mitems*[T](self: PyList[T]): var T =
  ## EXT.
  for i in self.data.mitems:
    yield i

func getPtr*[T](self: var PyList[T], i: Natural|BackwardsIndex): ptr T =
  ## EXT.
  ## unstable.
  ## used by Lib/array `frombytes` and `tobytes`.
  when NimMajor == 1:
    self.data[i].unsafeAddr
  else:
    self.data[i].addr
