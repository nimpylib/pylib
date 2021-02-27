import std/strutils

template str*(a: untyped): string = $a
template unicode*(a: untyped): string = $a
template ascii*(a: untyped): string = $a
template u*(a: string): string = a
template u*(a: char): string = $a
template b*(a: string): string = a
template b*(a: char): string = $a
template int*(a: string): BiggestInt = parseBiggestInt(a)
template int*(a: char): BiggestInt = parseBiggestInt($a)
template int*[T: SomeNumber](a: T): untyped = system.int(a)
template int*(a: bool): int = (if a: 1 else: 0)
template long*(a: string): BiggestInt = parseBiggestInt(a)
template long*(a: char): BiggestInt = parseBiggestInt($a)
template long*[T: SomeNumber](a: T): untyped = system.int(a)
template long*(a: bool): int = (if a: 1 else: 0)
template float*(a: string): BiggestFloat = parseFloat(a)
template float*[T: SomeNumber](a: T): untyped = system.float(a)
template float*(a: bool): float = (if a: 1.0 else: 0.0)
