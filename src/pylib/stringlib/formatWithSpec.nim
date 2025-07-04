
import std/macros


macro declWhenNotRunArgs(args; decl) =
  args.expectMinLen 1
  var call = newCall(decl.name)
  for i in args: call.add i
  quote do:
    when not compiles(`call`): `decl`

from std/strutils import formatBiggestFloat
from std/unicode import runeLen, runeOffset, Rune, `$`
import std/strformat{.all.}


proc myToRadix(typ: char): int =
  ## XXX: differs from the one in std/strformat,
  ## which fails to handle 'i' and 'u'
  case typ
  of 'x', 'X': 16
  of 'd', 'i', 'u', '\0': 10
  of 'o': 8
  of 'b': 2
  else:
    raise newException(ValueError,
      "invalid type in format string for number, expected one " &
      " of 'x', 'X', 'b', 'd', 'i', 'u', 'o' but got: " & typ)

# The following ones marked by `declWhenNotRunArgs` are just copied from std/strformat

proc mkDigit(v: int, typ: char): string {.inline, declWhenNotRunArgs((1, 'x')).} =
  assert(v < 26)
  if v < 10:
    result = $chr(ord('0') + v)
  else:
    result = $chr(ord(if typ == 'x': 'a' else: 'A') + v - 10)

const DefSpec = StandardFormatSpecifier()
proc formatInt(n: SomeNumber; radix: int; spec: StandardFormatSpecifier): string{.declWhenNotRunArgs((1, 16, DefSpec)).} =
  ## Converts `n` to a string. If `n` is `SomeFloat`, it casts to `int64`.
  ## Conversion is done using `radix`. If result's length is less than
  ## `minimumWidth`, it aligns result to the right or left (depending on `a`)
  ## with the `fill` char.
  when n is SomeUnsignedInt:
    var v = n.uint64
    let negative = false
  else:
    let n = n.int64
    let negative = n < 0
    var v =
      if negative:
        # `uint64(-n)`, but accounts for `n == low(int64)`
        uint64(not n) + 1
      else:
        uint64(n)

  var xx = ""
  if spec.alternateForm:
    case spec.typ
    of 'X': xx = "0x"
    of 'x': xx = "0x"
    of 'b': xx = "0b"
    of 'o': xx = "0o"
    else: discard

  if v == 0:
    result = "0"
  else:
    result = ""
    while v > typeof(v)(0):
      let d = v mod typeof(v)(radix)
      v = v div typeof(v)(radix)
      result.add(mkDigit(d.int, spec.typ))
    for idx in 0..<(result.len div 2):
      swap result[idx], result[result.len - idx - 1]
  if spec.padWithZero:
    let sign = negative or spec.sign != '-'
    let toFill = spec.minimumWidth - result.len - xx.len - ord(sign)
    if toFill > 0:
      result = repeat('0', toFill) & result

  if negative:
    result = "-" & xx & result
  elif spec.sign != '-':
    result = spec.sign & xx & result
  else:
    result = xx & result

  if spec.align == '<':
    for i in result.len..<spec.minimumWidth:
      result.add(spec.fill)
  else:
    let toFill = spec.minimumWidth - result.len
    if spec.align == '^':
      let half = toFill div 2
      result = repeat(spec.fill, half) & result & repeat(spec.fill, toFill - half)
    else:
      if toFill > 0:
        result = repeat(spec.fill, toFill) & result


proc formatValue*[T: SomeInteger](s: var string, value: T, spec: StandardFormatSpecifier) =
  s.add formatInt(value, spec.typ.myToRadix, spec)


proc toFloatFormatMode(typ: char): FloatFormatMode{.declWhenNotRunArgs(('e')).} =
  case typ
  of 'e', 'E': ffScientific
  of 'f', 'F': ffDecimal
  of 'g', 'G': ffDefault
  of '\0': ffDefault
  else:
    raise newException(ValueError,
      "invalid type in format string for number, expected one " &
      " of 'e', 'E', 'f', 'F', 'g', 'G' but got: " & typ)

proc formatValue*(result: var string, value: SomeFloat, spec: StandardFormatSpecifier) =
  let fmode = toFloatFormatMode(spec.typ)
  formatFloat(result, value, fmode, spec)


proc formatValue*(result: var string; value: string; spec: StandardFormatSpecifier) =
  # XXX: NOTE: we don't only allow 's' as spec.typ, but also 'a', 'r', etc.
  # considering spec.typ does no affect here, and we've checked before calling this func,
  # we just do not check here
  var value = value
  if spec.precision != -1:
    if spec.precision < runeLen(value):
      let precision = cast[Natural](spec.precision)
      setLen(value, Natural(runeOffset(value, precision)))

  result.add alignString(value, spec.minimumWidth, spec.align, spec.fill)

proc formatValue*(result: var string; value: char|Rune; spec: StandardFormatSpecifier) =
  if spec.precision == 0:
    return
  result.add alignString($value, spec.minimumWidth, spec.align, spec.fill)
