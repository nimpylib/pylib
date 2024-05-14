

import std/unicode
from std/strutils import contains
type
  PyStr* = distinct string  ## Python `str`, use `func str` to get an instance

type StringLike* = string | char | PyStr

func str*(self: PyStr): PyStr = self  ## copy
func str*(`object` = ""): PyStr = PyStr(`object`)
func str*(a: Rune): PyStr = str $a
func str*(c: char): PyStr = str $c

template str*[O: object](o: O): PyStr =
  '<' & $O & " object at " & $o.addr & '>'
template str*[T](a: T): PyStr =
  ## convert any object based on `repr`
  ## 
  ## This is alreadly a fallback,
  ## used for types without `str` defined.
  ## 
  ## In Python, if a object's type has no `__str__`,
  ## then it falls to use `__repr__`
  mixin repr
  str repr a

using self: PyStr
using mself: var PyStr
func `$`*(self): string{.borrow.}  ## to Nim string
func fspath*(self): PyStr = self  ## make a PathLike
converter toNimStr*(self): string = $self
converter toPyStr*(s: string): PyStr = str(s)
converter toPyStr*(s: char): PyStr = str(s)
converter toPyStr*(s: Rune): PyStr = str(s)

# do not borrow contains(PyStr, char) here, as that'll make compile deadloop
# this `contains` is handled by collections_abc.Sequence
func contains*(s: PyStr; c: string): bool{.borrow.}
func contains*(s: PyStr; c: PyStr): bool{.borrow.}

func `==`*(self; o: PyStr): bool{.borrow.}
func `==`*(self; o: string): bool{.borrow.}
func `==`*(o: string; self): bool{.borrow.}
func add(mself; s: string){.borrow.} # inner use
func add(mself; s: char){.borrow.}   # inner use
func `&`(self; s: PyStr): string{.borrow.}  # inner use

func `+`*(self; s: PyStr): PyStr = PyStr(self & s)
func `+`*(self; s: StringLike): PyStr = self + str(s)

func `+=`*(mself; s: PyStr) = mself.add $s
func `+=`*(mself; s: char) = mself.add s
func `+=`*(mself; s: string) = mself.add s

func len*(self): int = runeLen $self
func len*(c: char): int = 1  ## len('c'), always returns 1
func byteLen*(self): int = system.len self  ## EXT. len of bytes
proc runeLenAt*(self; i: Natural): int{.borrow.} ## EXT. `i` is byte index
proc substr*(self; start, last: int): PyStr{.borrow.} ## EXT. byte index
func runeAtPos*(self; pos: int): Rune{.borrow.}
func `[]`*(self; i: int): PyStr =
  runnableExamples:
    assert str("你好")[1] == str("好")
  str string(self).runeStrAtPos(if i < 0: len(self)+i else: i)

func `[]`*(self; i: Slice[int]): PyStr =
  ## EXT.
  ## `s[1..2]` means `s[1:3]`, and the latter is not valid Nim code
  let le = i.b + 1 - i.a
  if le <= 0: str()
  else: str string(self).runeSubStr(i.a, le)
func `[]`*(self; i: HSlice[int, BackwardsIndex]): PyStr =
  self[i.a .. len(self) - int(i.b) ]

iterator items*(self): PyStr =
  for r in self.runes:
    yield str r

iterator runes*(self): Rune =
  ## EXT.
  for r in self.string.runes:
    yield r

template `and`*(a, b: PyStr): PyStr =
  ## Mimics Python str and str -> str.
  ## Returns `a` if `a` is not empty, otherwise b (even if it's empty)
  if a.byteLen > 0: b else: a

template `or`*(a, b: PyStr): PyStr =
  ## Mimics Python str or str -> str.
  ## Returns `a` if `a` is not empty, otherwise b (even if it's empty)
  if a.byteLen > 0: a else: b

template `not`*(s: PyStr): bool =
  ## # Mimics Python not str -> bool.
  ## "not" for strings, return true if the string is not nil or empty.
  s.byteLen == 0
