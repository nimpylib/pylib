import strutils, unicode
from strformat import `&`

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

func index*[T: string | char](a: string, b: T, start = 0, last = 0): int =
  result = a.find(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

func rindex*[T: string | char](a: string, b: T, start = 0, last = 0): int =
  result = a.rfind(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

func isspace*[T: string | char](a: T): bool = unicode.isSpace($a)

template join*(sep: string, a: openArray[untyped]): string =
  ## Mimics Python join() -> string
  a.join(sep)

template join*(sep: char, a: openArray[untyped]): string =
  ## Mimics Python join() -> string
  a.join($sep)

func casefold*[T: string | char](a: T): string | char =
  ## Mimics Python str.casefold() -> bool
  unicode.toLower(a)

func center*[T: string | char](a: T, width: Natural, fillchar: char=' '): string | char =
  ## Mimics Python str.center(width: int, fillchar: str=" ") -> str
  repeat(fillchar, width) & a & repeat(fillchar, width)

func capwords*[T: string](a: T, sep: char=' '): string =
  ## Mimics Python string.capwords(sep) -> str
  for word in split(strutils.strip($a), $sep):
      result.add(strutils.capitalizeAscii(word))
      result.add($sep)
  result = strutils.strip(result)

func isalnum*[T: string | char](a: T): bool =
  ## Mimics Python str.isalnum() -> bool
  strutils.isAlphaNumeric($a)

func `or`*(a, b: string): string =
  ## Mimics Python str or str -> str.
  ## "or" for string,return a if a is not "" or empty else b,or empty if b is "".
  if a != "": a else: b

func `not`*(s: string): bool =
  ## # Mimics Python not str -> bool.
  ## "not" for strings, return true if the string is not nil or empty.
  s == ""

template f*(pattern: string): untyped =
  ## An alias for ``&``. Mimics Python F-String.
  bind `&`
  &pattern
