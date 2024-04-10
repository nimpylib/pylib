import std/strutils

type StringLike* = string | char

template `*`*(a: StringLike, b: int): string = a.repeat(b)

template `+`*[A: StringLike, B: StringLike](a: A, b: B): string = a & b

template `==`*[A: StringLike, B: StringLike](a: A, b: B): bool = $a == $b
# Python 1.x and 2.x
template `<>`*[A: StringLike, B: StringLike](a: A, b: B): bool = $a != $b

template `or`*(a, b: string): string =
  ## Mimics Python str or str -> str.
  ## Returns `a` if `a` is not empty, otherwise b (even if it's empty)
  if a.len > 0: a else: b

template `not`*(s: string): bool =
  ## # Mimics Python not str -> bool.
  ## "not" for strings, return true if the string is not nil or empty.
  s.len == 0
