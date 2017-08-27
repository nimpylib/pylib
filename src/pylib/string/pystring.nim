import strutils
export strutils

const
  ascii_lowercase = "abcdefghijklmnopqrstuvwxyz"
  ascii_uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  ascii_letters = ascii_lowercase & ascii_uppercase
  digits = "0123456789"
  hexdigits = "0123456789abcdefABCDEF"
  octdigits = "01234567"
  punctuation = """!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~"""
  whitespace = " \t\n\r\x0b\x0c"
  printable = digits & ascii_letters & punctuation & whitespace

proc index*[T: string | char](a: string, b: T, start = 0, last = 0): int = 
  result = a.find(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

proc rindex*[T: string | char](a: string, b: T, start = 0, last = 0): int = 
  result = a.rfind(b, start, last)
  if result == -1:
    raise newException(ValueError, "substring not found")

proc isspace*[T: string | char](a: T): bool = 
  result = true
  for x in a:
    if x notin whitespace:
      return false

template join*(sep: string, a: openArray[untyped]): string = a.join(sep)
template join*(sep: char, a: openArray[untyped]): string = a.join($sep)