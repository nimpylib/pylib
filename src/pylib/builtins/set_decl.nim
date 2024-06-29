
import std/sets

type
  set*[H] = ref object
    data: HashSet[H]
  PySet*[H] = set_decl.set[H]

func asHashSet*[H](self: PySet[H]): HashSet[H] = self.data
func asHashSet*[H](self: var PySet[H]): var HashSet[H] = self.data
func newPySet*[H](h: HashSet[H]): PySet[H] = PySet[H](data: h)

proc incl*[H](self: var PySet[H], x: H) = self.data.incl x
proc excl*[H](self: var PySet[H], x: H) = self.data.excl x

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
