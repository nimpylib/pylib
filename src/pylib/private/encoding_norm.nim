

import std/strutils

# not the same as Py's C-API, but here is fine.
template Py_ISALNUM(c: char): bool = c.isAlphaNumeric()
template Py_TOLOWER(c: char): char = c.toLowerAscii()

# translated from CPython-3.13-alpha/Object/unicodeobjetc.c L3234
# `_Py_normalize_encoding`, but use Nim's string over C's char pointer.
template Py_normalize_encoding_impl(encoding: string, map2char) =
  var punct = false
  for c in encoding:
    if Py_ISALNUM(c) or c == '.':
      if punct and result.len != 0:
        result.add '_'
      punct = false
      result.add map2char(c)
    else:
      punct = true

proc Py_normalize_encoding*(encoding: string): string =
  ##  Normalize an encoding name: similar to encodings.normalize_encoding(), but
  ##    also convert to lowercase.
  Py_normalize_encoding_impl(encoding, Py_TOLOWER)


proc `encodings.normalize_encoding`*(encoding: string): string =
  ##[ Normalize an encoding name.

    Normalization works as follows: all non-alphanumeric
    characters except the dot used for Python package names are
    collapsed and replaced with a single underscore, e.g. '  -;#'
    becomes '_'. Leading and trailing underscores are removed.

    Note that encoding names should be ASCII only.
  ]##
  template as_is(c: char): char = c
  Py_normalize_encoding_impl(encoding, as_is)

