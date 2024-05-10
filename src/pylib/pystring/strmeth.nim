
import std/unicode except split
import std/strutils except strip, split, rsplit

import ./strimpl
import ./strip, ./split/[split, rsplit]
export strip, split, rsplit
import ./errHandle
import ../pyerrors

template `*`*(a: StringLike, i: int): PyStr =
  bind repeat
  a.repeat(i)
template `*`*(i: int, a: StringLike): PyStr =
  bind `*`
  a * i

func count*(a: StringLike, sub: StringLike): int =
  if sub.len == 0: return str(a).len + 1

func count*(a: StringLike, sub: StringLike, start: int): int =
  let subA = substr($a, start)
  if sub.len == 0: return str(subA).len + 1
  count($a, sub)

func count*(a: StringLike, sub: StringLike, start=0, `end`: int): int =
  count(substr($a, start, `end`-1), sub)

template casefold*(a: StringLike): string =
  ## Mimics Python str.casefold() -> str
  unicode.toLower(a)

func lower*(a: StringLike): PyStr = toLower $a
func upper*(a: StringLike): PyStr = toUpper $a

func capitalize*(a: StringLike): PyStr =
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
  result = $toUpper(rune) + substr(s, i).lower()


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

template retIfWider(a: char) =
  if 1 >= width:
    return str(a)
template retIfWider(a: StringLike) =
  if len(a) >= width:
    return str(a)

template centerImpl(a, width, fillchar) =
  let
    hWidth = (width-len(a)) div 2
    half = fillchar.repeat(hWidth)
  result = half + a + half

func center*(a: StringLike, width: int, fillchar = ' '): PyStr =
  ## Mimics Python str.center(width: int, fillchar: str=" ") -> str
  retIfWider a
  centerImpl a, width, fillchar

func ljust*(a: StringLike, width: int, fillchar = ' ' ): PyStr =
  alignLeft $a, width, fillchar
func rjust*(a: StringLike, width: int, fillchar = ' ' ): PyStr =
  align $a, width, fillchar

template chkLen(a): int = 
  ## 1. returns if wider; 2. raises if not 1 len; 3. length as result
  retIfWider a
  let le = len(fillchar)
  if le != 1:
    raise newException(TypeError, 
      "The fill character must be exactly one character long")
  le

func center*(a: StringLike, width: int, fillchar: PyStr): PyStr =
  discard chkLen a
  centerImpl(a, width, fillchar[0])

func ljust*(a: StringLike, width: int, fillchar: PyStr): PyStr =
  let le = chkLen a
  let fills = (width - le) * fillchar
  result = a + fills
  
func rjust*(a: StringLike, width: int, fillchar: PyStr ): PyStr =
  let le = chkLen a
  let fills = (width - le) * fillchar
  result = fills + a

func zfill*(c: char, width: int): PyStr =
  if 1 >= width:
    return str(c)
  # Now `width` is at least 2.
  let zeroes = '0'.repeat(width-1)
  if c == '+' or c == '-':
    return str(c & zeroes)
  result = str(zeroes & c)

func zfill*(a: StringLike, width: int): PyStr =
  let le = len(a)
  var res = $a
  if le >= width:
    return str(res)
  let fill = width - le
  let zeroes = '0'.repeat(fill)
  if le == 0:
    return str(zeroes)

  let first = res[0]
  res = zeroes & res
  if first == '+' or first == '-':
    # move sign to beginning of string
    res[fill] = '0'
    res[0] = first
  result = str(res)

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

template partitionGen(name; find){.dirty.} =
  func name*(a: StringLike, sep: StringLike): tuple[before, sep, after: PyStr] =
    noEmptySep(sep)
    let idx = a.find(sep)
    if idx == -1:
      result.before = a
      return
    result = (a[0..<idx], sep, a[idx+len(sep) .. ^1] )

partitionGen partition, find
partitionGen rpartition, rfind
