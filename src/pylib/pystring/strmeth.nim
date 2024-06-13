
import std/unicode except split
import std/strutils except strip, split, rsplit
import std/tables

import ./strimpl
import ./strip, ./split/[split, rsplit]
export strip, split, rsplit
import ../stringlib/meth
import ../version
include ./unicase/toUpperMapper

const OneUpperToMoreTable = toTable OneUpperToMoreTableLit

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

func py_toLower(s: string): string =
  result = newStringOfCap s.len
  for ch in s.runes:
    if ch == Rune(304):
      result.add "i\u0307"
      continue
    result.add toLower ch

func py_toUpper(s: string): string =
  result = newStringOfCap s.len
  for ch in s.runes:
    let s = OneUpperToMoreTable.getOrDefault ch.int32
    if s.len == 0:
      result.add ch.toUpper
    else:
      result.add s

func lower*(a: PyStr): PyStr =
  ## str.lower
  ## 
  ## not the same as Nim's `unicode.toLower`, see examples
  runnableExamples:
    import std/unicode
    let dotI = Rune 0x0130  # İ  (LATIN CAPITAL LETTER I WITH DOT ABOVE)
    assert str(dotI).lower() == "i\u0307"  ## i̇ (\u0207 is a upper dot)
    assert dotI.toLower() == Rune('i')
  str py_toLower $a
func upper*(a: PyStr): PyStr =
  ## str.upper
  ## 
  ## not the same as Nim's `unicode.toUpper`, see examples
  runnableExamples:
    import std/unicode
    let a = "ᾷ"
    # GREEK SMALL LETTER ALPHA WITH PERISPOMENI AND YPOGEGRAMMENI
    assert str(a).upper() == "Α͂Ι"  # 3 chars
    assert a.toUpper() == a   # Nim just maps it as-is.
    # There is more examples... (101 characters in total)
  str py_toUpper $a

func isCased(r: Rune): bool =
  ## Unicode standard 5.0 introduce `isCased`
  r.isLower or r.isUpper or r.isTitle

type RuneImpl = int32
proc py_toTitle(r: Rune): Rune =
  ## unicode.toTitle only respect those whose
  ## titlecase differs uppercase.
  ## e.g.
  ##  not respect ascii
  var c = RuneImpl(r)
  if c <= RuneImpl high char:
    return cast[char](c).toUpperAscii.Rune
  result = r.toTitle()
  if result == r:
    # Nim's toTitle only convert those whose titlecase differs uppercase.
    return r.toUpper()
    ## when it comes to Ligatures,
    ##  toUpper() will do what `title()` in Python does
    ##  for example, `'ῃ'.upper()` gives `'HI'` in Python (length becomes 2)
    ##  but Nim's `toUpper`'s result is always of 1 length, and
    ##  `"ῃ".runeAt(0).toUpper` gives `ῌ`, a.k.a. `'ῃ'.title()` in Python. 

func title*(a: PyStr): PyStr =
  ## str.title()
  ## 
  ## not the same as `title proc` in std/unicode, see example.
  runnableExamples:
    let s = "ǉ"  # \u01c9
    let u = str(s)
    assert u.title() == "ǈ"  # \u01c8
    import std/unicode
    assert unicode.title(s) == "Ǉ"  # \u01c7
  # currently titleImpl is ok for ascii only.
  #result.titleImpl a, isUpper, isLower, toUpper, toLower, runes, `+=`
  var previous_is_cased = false
  var res = newStringOfCap a.byteLen
  for ch in a.runes:
    res.add:
      if previous_is_cased: ch.toLower
      else: ch.py_toTitle
    previous_is_cased = ch.isCased
  result = str res

func capitalize*(a: PyStr): PyStr =
  ## make the first character have title/upper case and the rest lower case.
  ## 
  ## changed when Python 3.8: the first character will have title case.
  ## 
  ## while Nim's `unicode.capitalize` only make the first character upper-case.
  let s = $a
  if len(s) == 0:
    return ""
  var
    rune: Rune
    i = 0
  fastRuneAt(s, i, rune, doInc = true)
  let first = when (PyMajor, PyMinor) < (3,8):
    py_toUpper(rune)
  else:
    py_toTitle(rune)
  result = $first + substr(s, i).lower()


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

