import std/strutils

import ./strimpl

template `*`*(a: StringLike, b: int): string = a.repeat(b)


# Python 1.x and 2.x
template `<>`*[A: StringLike, B: StringLike](a: A, b: B): bool = $a != $b
