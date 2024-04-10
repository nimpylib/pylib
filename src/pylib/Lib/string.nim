
import std/strutils
import ../pystring

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


func capwords*(a: StringLike): string =
  ## Mimics Python string.capwords(s) -> str:
  ## 
  ## Runs of whitespace characters are replaced by a single space
  ##  and leading and trailing whitespace are removed.
  for word in pystring.split(strutils.strip($a)):
    result.add(pystring.capitalize(word))
    result.add(" ")
  result = strutils.strip(result)

func capwords*(a: StringLike, sep: StringLike): string =
  ## Mimics Python string.capwords(s, sep) -> str:
  ## 
  ## Split the argument into words using split, capitalize each
  ##  word using `capitalize`, and join the capitalized words using
  ##  `join`. `sep` is used to split and join the words.
  let ssep = $sep
  for word in pystring.split($a, ssep):
    result.add(unicode.capitalize(word))
    result.add(ssep)

