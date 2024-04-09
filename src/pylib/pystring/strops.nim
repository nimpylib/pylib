import std/strutils

type StringLike* = string | char

template `*`*(a: StringLike, b: int): string = a.repeat(b)

template `+`*[A: StringLike, B: StringLike](a: A, b: B): string = a & b

template `==`*[A: StringLike, B: StringLike](a: A, b: B): bool = $a == $b
# Python 1.x and 2.x
template `<>`*[A: StringLike, B: StringLike](a: A, b: B): bool = $a != $b