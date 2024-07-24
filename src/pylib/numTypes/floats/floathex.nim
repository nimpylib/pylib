
from std/parseutils import skipWhile, parseInt
from std/strutils import find, initSkipTable, isSpaceAscii, toLowerAscii,
  HexDigits
import std/fenv
from std/math import frexp, classify, FloatClass
from ../../Lib/math import ldexp
import ./parse_inf_nan

#[ we can use sprintf(.., %a ..) here, but it may be less effective and less error-reportable:
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
  DBL_MAX_EXP = float64.maxExponent
const
  TOHEX_NBITS = DBL_MANT_DIG + 3 - (DBL_MANT_DIG+2) mod 4
  HEX_BUF = (TOHEX_NBITS-1)/4+3  # not sure if too long

const Py_hexdigits = "0123456789abcdef"

func char_from_hex(x: int): char = Py_hexdigits[x]
func hex_from_char(c: char): int =
  case c
  of '0': 0
  of '1': 1
  of '2': 2
  of '3': 3
  of '4': 4
  of '5': 5
  of '6': 6
  of '7': 7
  of '8': 8
  of '9': 9
  of 'a', 'A': 10
  of 'b', 'B': 11
  of 'c', 'C': 12
  of 'd', 'D': 13
  of 'e', 'E': 14
  of 'f', 'F': 15
  else: -1

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

# ======= fromhex =======
template IS_SPACE(c): bool = isSpaceAscii(c)

func floatFromhexImpl*(s: string): float =
  const
    LONG_MAXd2 = high(int) div 2
    LONG_MINd2 = low(int) div 2
  #[For the sake of simplicity and correctness, we impose an artificial
  limit on ndigits, the total number of hex digits in the coefficient
  The limit is chosen to ensure that, writing exp for the exponent,
      *
    (1) if exp > LONG_MAX/2 then the value of the hex string is
    guaranteed to overflow (provided it's nonzero)
      *
    (2) if exp < LONG_MIN/2 then the value of the hex string is
    guaranteed to underflow to 0.
      *
    (3) if LONG_MIN/2 <= exp <= LONG_MAX/2 then there's no danger of
    overflow in the calculation of exp and top_exp below.
      *
  More specifically, ndigits is assumed to satisfy the following
  inequalities:
      *
    4*ndigits <= DBL_MIN_EXP - DBL_MANT_DIG - LONG_MIN/2
    4*ndigits <= LONG_MAX/2 + 1 - DBL_MAX_EXP
      *
  If either of these inequalities is not satisfied, a ValueError is
  raised.  Otherwise, write x for the value of the hex string, and
  assume x is nonzero.  Then
      *
    2**(exp-4*ndigits) <= |x| < 2**(exp+4*ndigits).
      *
  Now if exp > LONG_MAX/2 then:
      *
    exp - 4*ndigits >= LONG_MAX/2 + 1 - (LONG_MAX/2 + 1 - DBL_MAX_EXP)
                    = DBL_MAX_EXP
      *
  so |x| >= 2**DBL_MAX_EXP, which is too large to be stored in C
  double, so overflows.  If exp < LONG_MIN/2, then
      *
    exp + 4*ndigits <= LONG_MIN/2 - 1 + (
                      DBL_MIN_EXP - DBL_MANT_DIG - LONG_MIN/2)
                    = DBL_MIN_EXP - DBL_MANT_DIG - 1
      *
  and so |x| < 2**(DBL_MIN_EXP-DBL_MANT_DIG-1), hence underflows to 0
  when converted to a C double.
      *
  It's easy to show that if LONG_MIN/2 <= exp <= LONG_MAX/2 then both
  exp+4*ndigits and exp-4*ndigits are within the range of a long.
  ]#
  let
    s_hi = s.high
    s_end = s.len
  var
    exp: int
    negate = false

  template raiseValueError(msg) =
    raise newException(ValueError, msg)
  template parse_error =
    raiseValueError "invalid hexadecimal floating-point string"
  template overflow_error =
    raise newException(OverflowDefect,
      "hexadecimal value too large to represent as a float")
  template insane_length_error =
    raiseValueError "hexadecimal string too long to convert"

  #[
    Parse the string
  ]#
  var curIdx = 0
  template inBound: bool = curIdx < s_end
  template cur: char = s[curIdx]
  template step = curIdx.inc
  template stepi(i) = curIdx.inc i
  template reset(i) = curIdx = i

  # leading whitespace
  while cur.IS_SPACE:
    step

  if result.Py_parse_inf_or_nan s.toOpenArray(curIdx, s_hi):
    return

  # optional sign
  let first = cur
  if first == '-': negate=true; step
  elif first == '+': step

  var s_store = curIdx
  # [0x|X]
  if cur == '0':
    step
    if cur == 'x' or cur == 'X':
      step
    else:
      reset s_store

  # coefficient: <integer> [. <fraction>]
  let coeff_start = curIdx
  stepi skipWhile(s, HexDigits, start=curIdx)
  s_store = curIdx
  let coeff_end =
    if inBound and cur == '.':
      step
      stepi skipWhile(s, HexDigits, start=curIdx)
      curIdx - 1
    else:
      curIdx

  #[ ndigits = total # of hex digits
     fdigits = # after point ]#
  var ndigits = coeff_end - coeff_start
  let fdigits = coeff_end - s_store
  if ndigits == 0:
    parse_error
  if ndigits > min(DBL_MIN_EXP - DBL_MANT_DIG - LONG_MINd2,
                   LONG_MAXd2 + 1 - DBL_MAX_EXP) div 4:
    insane_length_error

  # [p <exponent>]
  template curIsOr(a, b: char): bool =
    inBound and (cur == a or cur == b)
  if curIsOr('p', 'P'):
    step
    let exp_start = curIdx
    if curIsOr('-', '+'):
      step
    if not inBound or cur not_in '0'..'9':
      parse_error
    step
    while inBound and cur in '0'..'9':
      step
    let n = parseInt(s, exp, exp_start)
    assert n != 0
  else:
    exp = 0
  
  # for 0 <= j < ndigits, HEX_DIGIT(j) gives the jth most significant digit
  template HEX_DIGIT(j): int =
    hex_from_char(s[
      if j < fdigits: coeff_end-j
      else: coeff_end-1-j
    ])
  #[
    Compute rounded value of the hex string
  ]#

  template finished =
    while inBound and cur.IS_SPACE:
      step
    if curIdx != s_end:
      parse_error
    if negate: result = -result
    return
  
  # Discard leading zeros, and catch extreme overflow and underflow
  while ndigits > 0 and HEX_DIGIT(ndigits-1) == 0:
    ndigits.dec
  if ndigits == 0 or exp < LONG_MINd2:
    result = 0.0
    finished
  if exp > LONG_MAXd2:
    overflow_error

  # Adjust exponent for fractional part.
  exp -= 4*fdigits

  # top_exp = 1 more than exponent of most sig. bit of coefficient
  var top_exp = exp + 4*(ndigits - 1)
  var digits = HEX_DIGIT(ndigits-1)
  while digits != 0:
    top_exp.inc
    digits = digits div 2

  # catch almost all nonextreme cases of overflow and underflow here
  if top_exp < DBL_MIN_EXP - DBL_MANT_DIG:
    result = 0.0
    finished
  if top_exp > DBL_MAX_EXP:
    overflow_error

  # lsb = exponent of least significant bit of the *rounded* value
  # This is top_exp - DBL_MANT_DIG unless result is subnormal.
  let lsb = max(top_exp, int(DBL_MIN_EXP)) - DBL_MANT_DIG

  result = 0.0
  template handleInTill(till) =
    for i in countdown(ndigits-1, till):
      result = 16.0*result + float HEX_DIGIT(i)
  if exp >= lsb:
    # no rounding required
    handleInTill 0
    result = ldexp(result, exp)
    finished
  # rounding required.  key_digit is the index of the hex digit
  # containing the first bit to be rounded away.
  let
    half_eps = 1 shl ((lsb - exp - 1) mod 4)
    key_digit = (lsb - exp - 1) div 4
  handleInTill key_digit+1
  let digit = HEX_DIGIT(key_digit)
  result = 16.0*result + float(digit and (16-2*half_eps))

  # round-half-even: round up if bit lsb-1 is 1 and at least one of
  # bits lsb, lsb-2, lsb-3, lsb-4, ... is 1.
  if (digit and half_eps) != 0:
    var round_up = false
    if (digit and (3*half_eps-1)) != 0 or (
        half_eps == 8 and
        key_digit+1 < ndigits and
        (HEX_DIGIT(key_digit+1) and 1) != 0):
      round_up = true
    else:
      for i in countdown(key_digit-1, 0):
        if HEX_DIGIT(i) != 0:
          round_up = true
          break
    if round_up:
      result += float 2*half_eps
      if top_exp == DBL_MAX_EXP and
          result == ldexp(float(2*half_eps), DBL_MANT_DIG):
        # overflow corner case:
        # pre-rounded value < 2**DBL_MAX_EXP; rounded=2**DBL_MAX_EXP.
        overflow_error
  result = ldexp(result, exp+4*key_digit)
  finished
