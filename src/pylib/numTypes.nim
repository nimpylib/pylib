
import std/strutils

type Int* = system.int  ## alias of system.int

template int*(a: string): Int =
  bind parseInt
  parseInt(a)
template int*(a: char): Int =
  bind parseInt
  parseInt($a)
template int*(a: bool): Int = (if a: 1 else: 0)

template long*(a: string): BiggestInt = parseBiggestInt(a)
template long*(a: char): BiggestInt = parseBiggestInt($a)
template long*[T: SomeNumber](a: T): BiggestInt = BiggestInt(a)
template long*(a: bool): int = BiggestInt(if a: 1 else: 0)

template float*(a: string): BiggestFloat =
  bind parseFloat
  parseFloat(a)
template float*(a: bool): BiggestFloat = (if a: 1.0 else: 0.0)
