import std/[strutils, unicode]

import ./strops

template casefold*(a: StringLike): string =
  ## Mimics Python str.casefold() -> str
  unicode.toLower(a)

template lower*(a: StringLike): string = toLower $a
template upper*(a: StringLike): string = toUpper $a

func capitalize*(a: StringLike): string =
  ## make the first character have upper case and the rest lower case.
  ## 
  ## while Nim's `unicode.capitalize` only make the first character upper-case.
  let s = $a
  if len(s) == 0:
    return ""
  var
    rune: Rune
    i = 0
  fastRuneAt(s, i, rune, doInc = true)
  result = $toUpper(rune) & toLower substr(s, i)


template seWith(seWith){.dirty.} =
  export strutils.seWith
  func sewith*(a: StringLike, suffix: char): bool =
    seWith($a, suffix)
  func sewith*[Tup: tuple](a: StringLike, suffix: Tup): bool =
    let s = $a
    for _, suf in suffix.fieldPairs:
      if s.sewith suf:
        return true
  func sewith*[Suf: StringLike | tuple](a: StringLike, suffix: Suf, start: int): bool =
    let s = $a
    s[start..^1].sewith(suffix)
  func sewith*[Suf: StringLike | tuple](a: StringLike, suffix: Suf,
      start, `end`: int): bool =
    let s = $a
    s[start..<`end`].sewith(suffix)

seWith startsWith
seWith endsWith

func index*(a: string, b: StringLike, start = 0, last = -1): int =
  var last = if last == -1: a.len else: last
  result = a.find(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

func rindex*(a: string, b: StringLike, start = 0, last = 0): int =
  result = a.rfind(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")


template isascii*(c: char): bool = ord(c) in 0..0x7F
func isascii*(a: string): bool =
  result = true
  if a.len == 0: return
  for c in a:
    if not c.isascii():
      return false

export isalpha

template allRunes(a, isWhat) =
  result = true
  for r in runes $a:
    if not r.isWhat:
      return false

func islower*(a: StringLike): bool = allRunes a, isLower
func isupper*(a: StringLike): bool = allRunes a, isUpper

template isspace*(a: StringLike): bool = unicode.isSpace($a)

template center*(a: StringLike, width: Natural, fillchar = ' '): string =
  ## Mimics Python str.center(width: int, fillchar: str=" ") -> str
  center($a, width, fillChar)

template join*[T](sep: StringLike, a: openArray[T]): string =
  ## Mimics Python join() -> string
  a.join($sep)


iterator split*(a: StringLike, maxsplit = -1): string =
  ## with unicode whitespaces as sep.
  ## 
  ## treat runs of whitespaces as one sep (i.e.
  ##   discard empty strings from result),
  ## while Nim's `unicode.split(s)` doesn't

  # the following line is a implementation that only respect ASCII whitespace
  #for i in strutils.split($a): if i != "": yield i
  for i in unicode.split($a, maxsplit=maxsplit):
    if i != "": yield i

func split*(a: StringLike, maxsplit = -1): seq[string] =
  for i in strmeth.split(a, maxsplit): result.add i

iterator split*(a: StringLike,
    sep: StringLike, maxsplit = -1): string{.inline.} =
  for i in strutils.split($a, $sep, maxsplit): yield i
  
func split*(a: StringLike, sep: StringLike, maxsplit = -1): seq[string] =
  for i in strmeth.split(a, sep, maxsplit): result.add i