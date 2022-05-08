import std/[strutils, unicode]
from std/strformat import fmt
import strops

const
  ascii_lowercase* = "abcdefghijklmnopqrstuvwxyz"
  ascii_uppercase* = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  ascii_letters* = ascii_lowercase & ascii_uppercase
  digits* = "0123456789"
  hexdigits* = "0123456789abcdefABCDEF"
  octdigits* = "01234567"
  punctuation* = """!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~"""
  whitespace* = " \t\n\r\x0b\x0c"
  printable* = digits & ascii_letters & punctuation & whitespace

func index*(a: string, b: StringLike, start = 0, last = -1): int =
  var last = if last == -1: a.len else: last
  result = a.find(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

func rindex*(a: string, b: StringLike, start = 0, last = 0): int =
  result = a.rfind(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

template isspace*(a: StringLike): bool = unicode.isSpace($a)

template join*(sep: StringLike, a: openArray[untyped]): string =
  ## Mimics Python join() -> string
  a.join($sep)

template casefold*(a: StringLike): string =
  ## Mimics Python str.casefold() -> bool
  unicode.toLower(a)

template center*(a: StringLike, width: Natural, fillchar = ' '): string =
  ## Mimics Python str.center(width: int, fillchar: str=" ") -> str
  repeat(fillchar, width) & a & repeat(fillchar, width)

func capwords*(a: StringLike, sep = ' '): string =
  ## Mimics Python string.capwords(sep) -> str
  for word in split(strutils.strip($a), $sep):
    result.add(strutils.capitalizeAscii(word))
    result.add($sep)
  result = strutils.strip(result)

template `or`*(a, b: string): string =
  ## Mimics Python str or str -> str.
  ## Returns `a` if `a` is not empty, otherwise b (even if it's empty)
  if a.len > 0: a else: b

template `not`*(s: string): bool =
  ## # Mimics Python not str -> bool.
  ## "not" for strings, return true if the string is not nil or empty.
  s.len == 0

template f*(pattern: static[string]): untyped =
  ## An alias for ``fmt``. Mimics Python F-String.
  bind `fmt`
  fmt(pattern)