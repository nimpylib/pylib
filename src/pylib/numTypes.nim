
import std/strutils

template int*(a: string): BiggestInt = parseBiggestInt(a)
template int*(a: char): BiggestInt = parseBiggestInt($a)
template int*[T: SomeNumber](a: T): system.int = system.int(a)
template int*(a: bool): int = (if a: 1 else: 0)
template long*(a: string): BiggestInt = parseBiggestInt(a)
template long*(a: char): BiggestInt = parseBiggestInt($a)
template long*[T: SomeNumber](a: T): system.int = system.int(a)
template long*(a: bool): int = (if a: 1 else: 0)
template float*(a: string): BiggestFloat = parseFloat(a)
template float*[T: SomeNumber](a: T): system.float = system.float(a)
template float*(a: bool): float = (if a: 1.0 else: 0.0)
