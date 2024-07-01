
import std/hashes
import std/sets
import ./private/strIter

type
  frozenset*[H] = ref object
    data: HashSet[H]
  PyFrozenSet*[H] = frozenset[H]
  set*[H] = ref object # in Python, they are distinct types.
    data: HashSet[H]
  PySet*[H] = set_decl.set[H]
  SomePySet*[H] = set_decl.set[H] | frozenset[H]

func hash*[H](self: PyFrozenSet[H]): int = int hash self.data

func asHashSet*[H](self: SomePySet[H]): HashSet[H] = self.data
func asHashSet*[H](self: var SomePySet[H]): var HashSet[H] = self.data
func newPySet*[H](h: HashSet[H]): PySet[H] = PySet[H](data: h)
func newPyFrozenSet*[H](h: HashSet[H]): PyFrozenSet[H] = PyFrozenSet[H](data: h)
func newPySet*[H](initialSize = defaultInitialSize): PySet[H] =
  PySet[H](data: initHashSet[H](initialSize))
func newPyFrozenSet*[H](initialSize = defaultInitialSize): PyFrozenSet[H] =
  PyFrozenSet[H](data: initHashSet[H](initialSize))

proc incl*[H](self: var SomePySet[H], x: H) = self.data.incl x
proc excl*[H](self: var SomePySet[H], x: H) = self.data.excl x

func len*(self: SomePySet): int = self.data.len

template repr*(self: PySet): string =
  bind strIterImpl
  mixin repr
  strIterImpl self, repr, '{', '}'

template repr*(self: PyFrozenSet): string =
  bind strIterImpl
  mixin repr
  strIterImpl self, repr, "frozenset({", "})"

template `$`*(self: SomePySet): string =
  bind repr
  repr self

proc clear*(self: var PySet): int = self.data.clear()
func `==`*(self, o: SomePySet): int = self.data == o.data
func `<=`*(self, o: SomePySet): int = self.data <= o.data
func `<`*(self, o: SomePySet): int = self.data < o.data
func contains*[H](self: SomePySet[H], x: H): bool = self.data.contains x
proc pop*[H](self: var PySet[H]): H{.discardable.} = self.data.pop()
iterator items*[H](self: SomePySet[H]): H =
  for i in self.data: yield i
export sets.items
