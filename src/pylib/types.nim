import strutils

template str*(a: untyped): string = $a
template int*(a: string): BiggestInt = parseBiggestInt(a)
template int*(a: char): BiggestInt = parseBiggestInt($a)
template int*[T: SomeNumber](a: T): untyped = system.int(a)
template float*(a: string): BiggestFloat = parseFloat(a)
template float*[T: SomeNumber](a: T): untyped = system.float(a)
