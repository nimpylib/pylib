import std/strutils
from std/unicode import runeAt, utf8

template str*(a: untyped): string = $a
template unicode*(a: untyped): string = $a

template ord(a: string): int = system.int(a.runeAt(0))
proc ascii*(us:string):string=
  ##   nim's Escape Char feature can be enabled via `-d:reprNimCharEsc`,
  ##     in which '\e' (i.e.'\x1B' in Nim) will be replaced by "\\e"
  result.add '\''
  for s in us.utf8:
    if s.len == 1:  # is a ascii char
      when defined(reprNimCharEsc):
        result.addEscapedChar s[0]
      else:
        let c = s[0]
        if c == '\e': result.add "\\x1b"
        else: result.addEscapedChar c
    else:
      result.add r"\u" & $ord(s)
  result.add '\''
template ascii*(a: untyped): string = ascii($a)

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
