
import std/unicode except split
import std/strutils except strip, split, rsplit

import ./strimpl
import ./strip, ./split/[split, rsplit]
export strip, split, rsplit
import ../stringlib/meth

# str.format is in ./format

template `*`*(a: StringLike, i: int): PyStr =
  bind repeat
  a.repeat(i)
template `*`*(i: int, a: StringLike): PyStr =
  bind `*`
  a * i

func count*(a: PyStr, sub: PyStr): int =
  meth.count(a, sub)

func count*(a: PyStr, sub: PyStr, start: int): int =
  meth.count(a, sub, start)

func count*(a: PyStr, sub: PyStr, start=0, `end`: int): int =
  meth.count(a, sub, start, `end`)

template casefold*(a: StringLike): string =
  ## Mimics Python str.casefold() -> str
  unicode.toLower(a)

func lower*(a: PyStr): PyStr = toLower $a
func upper*(a: PyStr): PyStr = toUpper $a

func title*(a: PyStr): PyStr =
  result.titleImpl a, isUpper, isLower, toUpper, toLower, runes, `+=`

func capitalize*(a: PyStr): PyStr =
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


export strutils.startsWith, strutils.endsWith

template seWith(seWith){.dirty.} =
  func sewith*(a: PyStr, suffix: char): bool =
    meth.seWith(a, suffix)
  func sewith*(a: char, suffix: PyStr): bool =
    meth.seWith(a, suffix)
  func sewith*[Tup: tuple](a: PyStr, suffix: Tup): bool =
    meth.seWith(a, suffix)
  func sewith*[Suf: PyStr | tuple](a: PyStr, suffix: Suf, start: int): bool =
    meth.seWith(a, suffix, start)
  func sewith*[Suf: PyStr | tuple](a: PyStr, suffix: Suf,
      start, `end`: int): bool =
    meth.seWith(a, suffix, start, `end`)

seWith startsWith
seWith endsWith

func find*(a: PyStr, b: PyStr, start = 0, `end` = len(a)): int =
  if b.len == 1:
    meth.find1(a, b, start)
  else:
    meth.find(a, b, start)

func rfind*(a: PyStr, b: PyStr, start = 0, `end` = len(a)): int =
  if b.len == 1:
    meth.rfind1(a, b, start)
  else:
    meth.rfind(a, b, start)

func index*(a, b: PyStr, start = 0, `end` = len(a)): int =
  if b.len == 1:
    meth.index1(a, b, start)
  else:
    meth.index(a, b, start)

func rindex*(a, b: PyStr, start = 0, `end` = len(a)): int =
  if b.len == 1:
    meth.rindex1(a, b, start)
  else:
    meth.rindex(a, b, start)

const AsciiOrdRange = 0..0x7F
func isascii*(a: Rune): bool = ord(a) in AsciiOrdRange
func isascii*(a: PyStr): bool =
  result = true
  if a.byteLen == 0: return
  for r in a.runes:
    if not r.isascii():
      return false

func isalpha*(a: PyStr): bool = unicode.isAlpha($a)

template firstChar(s: PyStr): Rune = s.runeAt 0
template strAllAlpha(s: PyStr, isWhat, notWhat): untyped =
  s.allAlpha isWhat, notWhat, runes, firstChar
func islower*(a: PyStr): bool = a.strAllAlpha isLower, isUpper
func isupper*(a: PyStr): bool = a.strAllAlpha isUpper, isLower
func istitle*(a: PyStr): bool =
  a.istitleImpl isUpper, isLower, runes, firstChar

func isspace*(a: PyStr): bool = unicode.isSpace($a)

func center*(a: PyStr, width: int, fillchar = ' '): PyStr =
  ## Mimics Python str.center(width: int, fillchar: str=" ") -> str
  meth.center(a, width, fillchar)

func ljust*(a: PyStr, width: int, fillchar = ' ' ): PyStr =
  meth.ljust a, width, fillchar
func rjust*(a: PyStr, width: int, fillchar = ' ' ): PyStr =
  meth.rjust a, width, fillchar

func center*(a: PyStr, width: int, fillchar: PyStr): PyStr =
  meth.center(a, width, fillchar)

func ljust*(a: PyStr, width: int, fillchar: PyStr): PyStr =
  meth.ljust(a, width, fillchar)
  
func rjust*(a: PyStr, width: int, fillchar: PyStr ): PyStr =
  meth.rjust(a, width, fillchar)

func zfill*(a: PyStr, width: int): PyStr =
  str meth.zfill($a, width)

func removeprefix*(a: PyStr, suffix: PyStr): PyStr =
  meth.removeprefix(a, suffix)
func removesuffix*(a: PyStr, suffix: PyStr): PyStr =
  meth.removesuffix(a, suffix)

func replace*(a: PyStr, sub, by: PyStr|char): PyStr =
  meth.replace(a, sub, by)

func join*[T](sep: PyStr, a: openArray[T]): PyStr =
  ## Mimics Python join() -> string
  meth.join(sep, a)

func partition*(a: PyStr, sep: PyStr): tuple[before, sep, after: PyStr] =
  meth.partition(a, sep)

func rpartition*(a: PyStr, sep: PyStr): tuple[before, sep, after: PyStr] =
  meth.rpartition(a, sep)

