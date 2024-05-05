

import std/unicode
type
  PyStr* = distinct string

type StringLike* = string | char | PyStr

func str*(`object` = ""): PyStr =
  PyStr(`object`)

func str*(a: Rune): PyStr = str $a
template str*[T](a: T): PyStr =
  mixin `$`
  str $a

using self: PyStr
using mself: var PyStr
func `$`*(self): string{.borrow.}
converter toNimStr*(self): string = $self
converter toPyStr*(s: string): PyStr = str(s)
converter toPyStr*(s: char): PyStr = str(s)
converter toPyStr*(s: Rune): PyStr = str(s)

func `==`*(self; o: PyStr): bool{.borrow.}
func add(mself; s: string){.borrow.}
func add(mself; s: char){.borrow.}

func `+`*(self; s: PyStr): PyStr = PyStr(self.string & s.string)
func `+`*(self; s: StringLike): PyStr = self + str(s)

func `+=`*(mself; s: PyStr) = mself.add $s
func `+=`*(mself; s: char) = mself.add s
func `+=`*(mself; s: string) = mself.add s

func len*(self): int = runeLen $self
func len*(c: char): int = 1
func byteLen*(self): int = system.len self  ## len of bytes
func runeAtPos*(self; pos: int): Rune{.borrow.}
func `[]`*(self; i: int): PyStr =
  str string(self).runeStrAtPos(if i < 0: len(self)+i else: i)

func `[]`*(self; i: Slice[int]): PyStr =
  let le = i.b + 1 - i.a
  if le <= 0: str()
  else: str string(self).runeSubStr(i.a, le)
func `[]`*(self; i: HSlice[int, BackwardsIndex]): PyStr =
  self[i.a .. len(self) - int(i.b) ]

iterator items*(self): PyStr =
  for r in self.runes:
    yield str r

iterator runes*(self): Rune =
  for r in self.string.runes:
    yield r

template `or`*(a, b: PyStr): PyStr =
  ## Mimics Python str or str -> str.
  ## Returns `a` if `a` is not empty, otherwise b (even if it's empty)
  if a.byteLen > 0: a else: b

template `not`*(s: PyStr): bool =
  ## # Mimics Python not str -> bool.
  ## "not" for strings, return true if the string is not nil or empty.
  s.byteLen == 0
