
import ./pybytes
export pybytes
import ./collections_abc
import std/strutils

# Begin impl
type
  PyByteArray* = ref object
    data: string
  BytesLike* = PyByteArray | PyBytes

using self: PyByteArray
using mself: PyByteArray

func newPyByteArray{.inline.}*: PyByteArray = PyByteArray()
func newPyByteArray*(s: sink string): PyByteArray{.inline.} = PyByteArray(data: s)
func newPyByteArray*(len: int): PyByteArray{.inline.} = PyByteArray(data: newString(len))

func bytes*(self: sink PyByteArray): PyBytes{.inline.} = bytes(self.data)

template asNim(self: PyByteArray): string =
  ## returns a mutable var
  self.data
converter toPyBytes*(self): PyBytes = bytes self.data
# then all non-inplace method are dispatched to PyBytes

func getCharPtr*(self; i: Natural|Natural): ptr char =
  ## EXT.
  ## unstable. 
  ## used by Lib/array `frombytes` and `tobytes`.
  self.data[i].addr

# End impl

template wrapCmp(op){.dirty.} =
  func op*(self; other: PyBytes): bool = op self.asNim, $other
  func op*(self; other: PyByteArray): bool = op self.asNim, other.asNim

wrapCmp `==`
wrapCmp `<=`
wrapCmp `<`

func `$`*(self): string = self.asNim
func toNimString*(self: PyByteArray): string = self.asNim
func toNimString*(self: var PyByteArray): var string = self.asNim

func bytearray*: PyByteArray = newPyByteArray()
func bytearray*(o: BytesLike): PyByteArray = newPyByteArray(o)
func bytearray*(s: string): PyByteArray = newPyByteArray s

func bytearray*(nbytes: int): PyByteArray =
  when not defined(release):
    if nbytes < 0:
      raise newException(ValueError, "negative count")
  newPyByteArray nbytes
func bytearray*(it: Iterable[char]): PyByteArray =
  ## EXT.
  var res: string
  for c in it:
    res.add it
  newPyByteArray res
func bytearray*(it: Iterable[int]): PyByteArray =
  var res: string
  for i in it:
    res.add i.chkChar
  newPyByteArray res

iterator chars*(self): char =
  for c in self.asNim:
    yield c

iterator items*(self): int =
  for c in self.chars:
    yield int(c)

func len*(self): int = self.asNim.len
when defined(danger):
  template chkChar(c: int): char = cast[char](c)
elif defined(release):
  template chkChar(c: int): char = char(c)
else:
  func chkChar(c: int): char =
    if c not_in 0..255:
      raise newException(ValueError, "byte must be in range(0, 256)")
    char(c)

template normIdx(i; self): int =
  if i < 0: self.len + i else: i
func `[]=`*(mself; i: int; val: int) =
  `[]=` mself.asNim, i.normIdx mself, val.char

func getChar*(self; i: Natural): char = self.asNim[i]
func `[]`*(self; i: Slice[int]): PyByteArray =
  ## EXT.
  ## `s[1..2]` means `s[1:3]`, and the latter is not valid Nim code
  let le = i.b + 1 - i.a
  if le <= 0: bytearray()
  else: bytearray ($self)[i]

func `[]`*(self; i: HSlice[int, BackwardsIndex]): PyByteArray =
  self[i.a .. len(self) - int(i.b) ]

func `[]=`*(mself; i: Slice[int], val: BytesLike) =
  ## EXT.
  ## `s[1..2]` means `s[1:3]`, and the latter is not valid Nim code
  let le = i.b + 1 - i.a
  if le <= 0: return
  else: (mself.asNim)[i] = val.toNimString

func `[]=`*(mself; i: HSlice[int, BackwardsIndex], val: BytesLike) =
  mself[i.a .. len(mself) - int(i.b) ] = val

func append*(mself; val: int) = add mself.asNim, val.chkChar
func extend*(mself; other: BytesLike) = add mself.asNim, other.toNimString
func `+=`*(mself; other: BytesLike) = mself.extend other


func copy*(self): PyByteArray = newPyByteArray(self.data)

# why system has no such a proc: `insert(string, char, i)`...

func insert*(mself; i: int, val: int) =
  # note nim's arg order differs Python's
  insert mself.asNim, $val.chkChar, i.normIdx mself

func pop*(mself): int =
  let hi = mself.len - 1
  result = mself[hi]
  mself.asNim.setLen hi

func remove*(mself; val: int) =
  let c = val.chkChar
  let idx = mself.asNim.find c
  if idx == -1: return
  mself.asNim.delete idx..idx

func delitem*(mself; i: int) =
  let idx = i.normIdx mself
  mself.asNim.delete idx..idx

func clear*(mself) = mself.asNim.setLen 0

func `*=`*(mself; n: int) =
  ## bytearray.__imul__
  ##
  ## Python: if n < 1: self.clear()
  if n < 1:
    mself.clear()
    return
  if n == 1: return
  mself += bytes mself.data.repeat n-1

func getCharRef(mself; i: int): var char = mself.asNim[i]

func reverse*(mself) =
  let hi = mself.len - 1
  for i in 0 .. hi div 2:
    swap mself.getCharRef(i), mself.getCharRef hi-i

