
type
  PyBytes* = distinct string

func bytes*(): PyBytes = PyBytes ""
func bytes*(s: string): PyBytes = PyBytes s  ## XXX: Currently no 
                                             ## `encode` and `errors` params

func bytes*(c: char): PyBytes = PyBytes $c

func bytes*(a: openArray[char]): PyBytes =
  PyBytes $a

template pybytes*[T](x: T): PyBytes =
  mixin bytes
  bytes(x)

using self: PyBytes
using mself: var PyBytes
func `$`*(self): string{.borrow.}  ## to Nim string
func fspath*(self): string = $self  ## make a PathLike
converter toNimString*(self): string = $self

# contains(PyBytes, int|PyButes): bool is in bytesmeth

func `==`*(self; o: PyBytes): bool{.borrow.}

func add(mself; s: string){.borrow.} # inner use
func add(mself; s: char){.borrow.}   # inner use
func `&`(self; o: PyBytes): PyBytes{.borrow.}
func `&`(self; o: string): PyBytes{.borrow.}
func `&`(self; o: char): PyBytes{.borrow.}

func `+`*(self; o: PyBytes): PyBytes = self & o
func `+`*(self; o: string): PyBytes = self & o
func `+`*(self; o: char): PyBytes = self & o

func `+`*(o: string, self): PyBytes = self & o
func `+`*(o: char, self): PyBytes = self & o

func `+=`*(mself; s: PyBytes) = mself.add $s
func `+=`*(mself; s: char) = mself.add s
func `+=`*(mself; s: string) = mself.add s


func len*(self): int{.borrow.}
func byteLen*(self): int = system.len self  ## EXT. the same as len(self)

proc substr*(self; start, last: int): PyBytes{.borrow.} ## EXT. byte index
proc substr*(self; start: int): PyBytes{.borrow.} ## EXT. byte index

func getChar*(self; i: int): char = cast[string](self)[i]  ## EXT.

func `[]`*(self; i: int): int =
  let c = self.getChar(if i < 0: len(self) + i else: i)
  cast[int](c)

func `[]`*(self; i: Slice[int]): PyBytes =
  ## EXT.
  ## `s[1..2]` means `s[1:3]`, and the latter is not valid Nim code
  let le = i.b + 1 - i.a
  if le <= 0: bytes()
  else: bytes ($self)[i]
func `[]`*(self; i: HSlice[int, BackwardsIndex]): PyBytes =
  self[i.a .. len(self) - int(i.b) ]

iterator chars*(self): char =
  ## EXT.
  for c in self.string:
    yield c

iterator items*(self): int =
  for c in self.string:
    yield cast[int](c)

template `or`*(a, b: PyBytes): PyBytes =
  ## Mimics Python str or str -> str.
  ## Returns `a` if `a` is not empty, otherwise b (even if it's empty)
  if a.byteLen > 0: a else: b

template `not`*(s: PyBytes): bool =
  ## # Mimics Python not str -> bool.
  ## "not" for strings, return true if the string is not nil or empty.
  s.byteLen == 0
