
import std/strutils except strip, split, rsplit

import ./errHandle
import ../pyerrors/simperr


template norm_idx(i, s): int =
  if i < 0: len(s) + i
  else: i

func count*[S](a: S, sub: S): int =
  if sub.len == 0: return a.len + 1
  count($a, $sub)

func count*[S](a: S, sub: S, start: int): int =
  let subA = substr($a, start.norm_idx(a))
  if sub.len == 0: return subA.len + 1
  count($a, $sub)

func count*[S](a: S, sub: S, start=0, `end`: int): int =
  count(substr($a, start.norm_idx(a), `end`.norm_idx(a) - 1), $sub)


template seWith(seWith){.dirty.} =
  template sewith*[S](a: S, suffix: char): bool =
    seWith($a, suffix)
  template sewith*[S](a: char, suffix: S): bool =
    suffix.len == 1 and a == suffix[0]
  func sewith*[S; Tup: tuple](a: S, suffix: Tup): bool =
    let s = $a
    for _, suf in suffix.fieldPairs:
      if s.sewith suf:
        return true
  func sewith*[S; Suf: S | tuple](a: S, suffix: Suf, start: int): bool =
    let s = $a
    substr(s, start.norm_idx(a)).sewith(suffix)
  func sewith*[S; Suf: S | tuple](a: S, suffix: Suf,
      start, `end`: int): bool =
    substr($a, start.norm_idx(a), `end`.norm_idx(a) - 1).sewith(suffix)

seWith startsWith
seWith endsWith


func find1*[S; T](a: S, b: T, start = 0): int =
  ## `b` shall be one length long.
  var i = start.norm_idx(a)
  for s in a:
    if s == b: return i
    i.inc
  return -1

func find1*[S; T](a: S, b: T, start = 0, `end`: int): int =
  ## `b` shall be one length long.
  var i = start.norm_idx(a)
  let last = `end`.norm_idx(a) - 1
  for s in a:
    if i == last: break
    if s == b: return i
    i.inc
  return -1

func rfind1*[S; T](a: S, b: T, start = 0, `end`: int): int =
  for i in countdown(`end`.norm_idx(a) - 1, start.norm_idx(a)):
    if a[i] == b: return i
  return -1
func rfind1*[S; T](a: S, b: T, start = 0): int =
  rfind1(a, b, start, len(a))

template gen_find(find){.dirty.} =
  func find*[S; T](a: S, b: T, start = 0): int =
    let i = start.norm_idx(a)
    strutils.find($a, $b, i)
  func find*[S; T](a: S, b: T, start = 0, `end`: int): int =
    let i = start.norm_idx(a)
    let last = `end`.norm_idx(a) - 1
    strutils.find($a, $b, i, last)

gen_find find
gen_find rfind

func rNoIdx{.inline.} =
  raise newException(ValueError, "substring not found")

func index1*[S; T](a: S, b: T, start = 0, `end`: int): int =
  result = a.find1(b, start, `end`)
  if result == -1: rNoIdx()
func index1*[S; T](a: S, b: T, start = 0): int =
  index1 a, b, start, len(a)
func index*[S; T](a: S, b: T, start = 0, `end`: int): int =
  result = a.find(b, start, `end`)
  if result == -1: rNoIdx()
func index*[S; T](a: S, b: T, start = 0): int =
  index a, b, start, len(a)

func rindex1*[S; T](a: S, b: T, start = 0, `end`: int): int =
  result = a.rfind1(b, start, `end`)
  if result == -1: rNoIdx()
func rindex1*[S; T](a: S, b: T, start = 0): int =
  rindex1 a, b, start, len(a)

func rindex*[S; T](a: S, b: T, start = 0, `end`: int): int =
  result = a.rfind(b, start, `end`)
  if result == -1: rNoIdx()
func rindex*[S; T](a: S, b: T, start = 0): int =
  rindex a, b, start, len(a)


const AsciiOrdRange = 0..0x7F

func isascii*(c: char): bool = ord(c) in AsciiOrdRange
func isascii*(s: string): bool =
  result = true
  if s.len == 0: return
  for c in s:
    if not c.isascii(): return false

template isspaceImpl(c: char): bool = c in Whitespace
template isdigitImpl(c: char): bool = strutils.isDigit(c) # just alias

template all(a: string, isX){.dirty.} =
  if a.len == 0: return
  result = true
  for c in a:
    if not c.isX():
      return false

template wrap2(isX, wrap){.dirty.} =
  func isX*(c: char): bool = c.wrap
  func isX*(s: string): bool = all(s, wrap)

wrap2 isalpha, isAlphaAscii
wrap2 isspace, isspaceImpl
wrap2 isdigit, isdigitImpl
wrap2 isalnum, isAlphaNumeric

template allAlpha*(a, isWhat, isNotWhat: typed, iter, firstItemGetter) =
  ## used as func body.
  ## e.g.
  ## func isupper(self: PyBytes): bool =
  ##   self.allAlpha(isUpperAscii, isLowerAscii, items, `[0]`)
  let le = len(a)
  if le == 1: return isWhat(a.firstItemGetter)
  if le == 0: return false
  var notRes = true
  for r in a.iter:
    if r.isNotWhat:
      return false
    elif notRes and r.isWhat:
      notRes = false
  result = not notRes

template istitleImpl*(a, isupper, islower: typed, iter, firstItemGetter) =
  let le = len(a)
  if le == 1:
    let c = a.firstItemGetter
    if c.isupper: return true
    return false
  if le == 0: return false

  var cased, previous_cased: bool

  for ch in a.iter:
    if ch.isupper:
      if previous_cased:
        return false
      previous_cased = true
      cased = true
    elif ch.islower:
      if not previous_cased:
        return false
      previous_cased = true
      cased = true
    else:
      previous_cased = false
  result = cased

template retIfWider[S](a: S) =
  if len(a) >= width:
    return a

template `*`(c: char, i: int): string =
  bind repeat
  c.repeat i
  
template centerImpl(a, width, fillchar) =
  let
    hWidth = (width-len(a)) div 2
    half = fillchar * hWidth
  result = half + a + half

func center*[S](a: S, width: int, fillchar = ' '): S =
  ## Mimics Python str.center(width: int, fillchar: str=" ") -> str
  retIfWider a
  centerImpl a, width, fillchar

func ljust*(a: string, width: int, fillchar = ' ' ): string =
  alignLeft $a, width, fillchar
func rjust*(a: string, width: int, fillchar = ' ' ): string =
  align $a, width, fillchar

template chkLen(a): int = 
  ## 1. returns if wider; 2. raises if not 1 len; 3. length as result
  retIfWider a
  let le = len(fillchar)
  if le != 1:
    raise newException(TypeError, 
      "The fill character must be exactly one character long")
  le

func center*[S](a: S, width: int, fillchar: S = " "): S =
  discard chkLen a
  centerImpl(a, width, fillchar)

func ljust*[S](a: S, width: int, fillchar: S = " "): S =
  let le = chkLen a
  let fills = (width - le) * fillchar
  result = a + fills
  
func rjust*[S](a: S, width: int, fillchar: S = " "): S =
  let le = chkLen a
  let fills = (width - le) * fillchar
  result = fills + a

func zfill*(c: char, width: int): string =
  if 1 >= width:
    return $c
  # Now `width` is at least 2.
  let zeroes = '0'.repeat(width-1)
  if c == '+' or c == '-':
    return c & zeroes
  result = zeroes & c

func zfill*(a: string, width: int): string =
  let le = len(a)
  var res = a
  if le >= width:
    return res
  let fill = width - le
  let zeroes = '0'.repeat(fill)
  if le == 0:
    return zeroes

  let first = res[0]
  res = zeroes & res
  if first == '+' or first == '-':
    # move sign to beginning of string
    res[fill] = '0'
    res[0] = first
  result = res

func removeprefix*[S](a: S, suffix: S): S =
  var res = $a
  strutils.removePrefix(res, suffix)
  S res
func removesuffix*[S](a: S, suffix: S): S =
  var res = $a
  strutils.removeSuffix(res, suffix)
  S res

func replace*[S](a: S, sub, by: char): S =
  S strutils.replace($a, sub, by)
func replace*[S](a: S, sub, by: S): S =
  S strutils.replace($a, $sub, $by)

func join*[T](sep: char, a: openArray[T]): string =
  a.join(sep)

func join*[T, S](sep: S, a: openArray[T]): S =
  ## Mimics Python join() -> string
  S a.join($(sep))

template partitionGen(name; find){.dirty.} =
  func name*[S](a: S, sep: S): tuple[before, sep, after: S] =
    noEmptySep(sep)
    let idx = a.find(sep)
    if idx == -1:
      result.before = a
      return
    result = (a[0..<idx], sep, a[idx+len(sep) .. ^1] )

partitionGen partition, find
partitionGen rpartition, rfind
