
import std/[unicode]
import std/strutils except strip

import ./strimpl
import ./strip
export strip

template casefold*(a: StringLike): string =
  ## Mimics Python str.casefold() -> str
  unicode.toLower(a)

func lower*(a: StringLike): string = toLower $a
func upper*(a: StringLike): string = toUpper $a

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
  template sewith*(a: StringLike, suffix: char): bool =
    seWith($a, suffix)
  template sewith*(a: char, suffix: string): bool =
    suffix.len == 1 and a == suffix[0]
  func sewith*[Tup: tuple](a: StringLike, suffix: Tup): bool =
    let s = $a
    for _, suf in suffix.fieldPairs:
      if s.sewith suf:
        return true
  func sewith*[Suf: StringLike | tuple](a: StringLike, suffix: Suf, start: int): bool =
    let s = $a
    substr(s, start).sewith(suffix)
  func sewith*[Suf: StringLike | tuple](a: StringLike, suffix: Suf,
      start, `end`: int): bool =
    let s = $a
    substr($a, start, `end`-1).sewith(suffix)

seWith startsWith
seWith endsWith


func find*(a: StringLike, b: StringLike, start = 0): int =
  var i = start
  for s in str(a):
    if s == b: return i
    i.inc
  return -1

func find*(a: StringLike, b: StringLike, start = 0, `end`: int): int =
  var i = start
  let last = `end` - 1
  for s in str(a):
    if i == last: break
    if s == b: return i
    i.inc
  return -1

func rfind*(a: StringLike, b: StringLike, start = 0, `end`: int): int =
  let sa = str(a)
  for i in countdown(`end`, start):
    if sa[i] == b: return i
  return -1

func rfind*(a: StringLike, b: StringLike, start = 0): int =
  let sa = str(a)
  sa.rfind(b, start, len(sa))

func index*(a, b: StringLike, start = 0, last = -1): int =
  result = a.find(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

func rindex*(a, b: StringLike, start = 0, last = -1): int =
  result = a.rfind(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

const AsciiOrdRange = 0..0x7F
func isascii*(c: char): bool = ord(c) in AsciiOrdRange
func isascii*(a: string): bool =
  result = true
  if a.len == 0: return
  for c in a:
    if not c.isascii():
      return false

func isascii*(a: Rune): bool = ord(a) in AsciiOrdRange
func isascii*(a: PyStr): bool =
  result = true
  if a.byteLen == 0: return
  for r in a.runes:
    if not r.isascii():
      return false

func isalpha*(c: char): bool = c.isAlphaAscii
func isalpha*(a: StringLike): bool = unicode.isAlpha($a)

template allRunes(a, isWhat) =
  result = true
  for r in runes $a:
    if not r.isWhat:
      return false
func islower*(c: char): bool = c.isLowerAscii
func isupper*(c: char): bool = c.isUpperAscii
func islower*(a: StringLike): bool = allRunes a, isLower
func isupper*(a: StringLike): bool = allRunes a, isUpper

func isspace*(a: StringLike): bool = unicode.isSpace($a)

func center*(a: PyStr|char, width: Natural, fillchar = ' '): PyStr =
  ## Mimics Python str.center(width: int, fillchar: str=" ") -> str
  let
    hWidth = (width-len(a)) div 2
    half = fillchar.repeat(hWidth)
  half + a + half

func ljust*(a: PyStr|char, width: int, fillchar = ' ' ): PyStr =
  alignLeft $a, width, fillchar
func rjust*(a: PyStr|char, width: int, fillchar = ' ' ): PyStr =
  align $a, width, fillchar

func removeprefix*(a: StringLike, suffix: StringLike): PyStr =
  result = $a
  strutils.removePrefix result, suffix
func removesuffix*(a: StringLike, suffix: StringLike): PyStr =
  result = $a
  strutils.removeSuffix result, suffix

func replace*(a, sub, by: StringLike): PyStr =
  strutils.replace($a, sub, by)

func join*[T](sep: StringLike, a: openArray[T]): PyStr =
  ## Mimics Python join() -> string
  a.join(str(sep))

iterator split*(a: StringLike, maxsplit = -1): PyStr =
  ## with unicode whitespaces as sep.
  ## 
  ## treat runs of whitespaces as one sep (i.e.
  ##   discard empty strings from result),
  ## while Nim's `unicode.split(s)` doesn't

  # the following line is a implementation that only respect ASCII whitespace
  #for i in strutils.split($a): if i != "": yield i
  for i in unicode.split($a, maxsplit=maxsplit):
    if i != "": yield i

iterator split*(a: StringLike,
    sep: StringLike, maxsplit = -1): PyStr{.inline.} =
  for i in strutils.split($a, $sep, maxsplit): yield i
  
func split*(a: StringLike, sep: StringLike, maxsplit = -1): seq[PyStr] =
  for i in strmeth.split(a, sep, maxsplit): result.add i
