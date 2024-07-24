

import std/fenv
from std/math import frexp, classify, FloatClass
from ../../Lib/math import ldexp

#[ we can use sprintf(.., %a ..) here, but it may be less effective:
when defined(c) or defined(cpp):
  proc sprintf(buf: cstring, fmt: cstring): c_int{.importc, header: "<stdio.h>", varargs.}
  func hexImpl(f: float): string =
    var buf = cast[cstring](alloc(HEX_BUF))
    let ret = sprintf(buf, "%a", f.c_double)
    assert ret == 1
    result = $buf
    buf.dealloc
]#
const
  DBL_MANT_DIG = float64.mantissaDigits
  DBL_MIN_EXP = float64.minExponent
const
  TOHEX_NBITS = DBL_MANT_DIG + 3 - (DBL_MANT_DIG+2) mod 4
  HEX_BUF = (TOHEX_NBITS-1)/4+3  # not sure if too long

const Py_hexdigits = "0123456789abcdef"
func char_from_hex(x: int): char = Py_hexdigits[x]
func hex_from_char(c: char): int =
  Py_hexdigits.find c

func normalFloatHexImpl(x: float): string =
  var (m, e) = frexp(abs(x))
  let shift = 1 - max(DBL_MIN_EXP - e, 0)
  m = ldexp(m, shift)
  e -= shift

  #[ Space for 1+(TOHEX_NBITS-1)/4 digits, a decimal point.]#
  const nDigits = (TOHEX_NBITS-1) div 4
  var s = newString nDigits + 2
  var si = 0
  s[si] = char_from_hex int m
  si.inc
  template dropIntPart(f: float) =
    f = f - float int f
  m.dropIntPart
  s[si] = '.'
  si.inc
  for i in 0..<nDigits:
    m *= 16.0
    s[si] = char_from_hex(int m)
    si.inc
    m.dropIntPart
  let esign =
    if e < 0:
      e = -e
      '-'
    else: '+'
  template push(cs) = result.add cs
  if x < 0.0:
    push '-'
  push "0x"
  push s
  push 'p'
  push esign
  push $e


func hexImpl*(x: float): string =
  let fc = x.classify
  case fc
  of fcNan: "nan"
  of fcInf: "inf"
  of fcNegInf: "-inf"
  of fcZero: "0x0.0p+0"
  of fcNegZero: "-0x0.0p+0"
  of fcNormal, fcSubNormal: normalFloatHexImpl(x)
