import strutils
import unicode
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

proc index*[T: string | char](a: string, b: T, start = 0, last = 0): int =
  result = a.find(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

proc rindex*[T: string | char](a: string, b: T, start = 0, last = 0): int =
  result = a.rfind(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

proc isspace*[T: string | char](a: T): bool = unicode.isSpace($a)

template join*(sep: string, a: openArray[untyped]): string = a.join(sep)
template join*(sep: char, a: openArray[untyped]): string = a.join($sep)

proc casefold*[T: string | char](a: T): string | char = unicode.toLower(a)

proc center*[T: string | char](a: T, width: Natural, fillchar: char=' '): string | char =
    ## Mimics Python str.center(width: int, fillchar: str=" ") -> str
    repeat($fillchar, width) + a + repeat($fillchar, width)

proc capwords*[T: string](a: T, sep: char=' '): string =
    ## Mimics Python string.capwords(sep) -> str
    for word in split($a.strip(), $sep):
        result.add(strutils.capitalizeAscii(word))
        result.add($sep)
    result.strip()

# Mimics Python str.isalnum() -> bool
proc isalnum*[T: string | char](a: T): bool = strutils.isAlphaNumeric($a)
