
import std/math
import ../pystring/strimpl
import ./floats/[init, floathex]
export init.float
import ../ops/chk_shl

func hex*(x: float): PyStr =
  str x.hexImpl

func fromhex*(_: typedesc[float], s: string): float =
  floatFromhexImpl s
func float_fromhex*(s: string): float =
  floatFromhexImpl s

func isfinite(x: SomeFloat): bool =
  let cls = classify(x)
  cls != fcInf and cls != fcNegInf and cls != fcNan
func is_integer*(self: float): bool =
  if not self.isfinite: false
  else: floor(self) == self

func as_integer_ratio_check(self: float){.inline.} =
  let fc = classify self
  if fc == fcInf or fc == fcNegInf: raise newException(OverflowDefect,
      "cannot convert Infinity to integer ratio")
  if fc == fcNan: raise newException(ValueError,
      "cannot convert NaN to integer ratio")

func as_integer_ratio*(self: float,
                 n: int = high(int) shr (sizeof(int) div 2 * 8)): (int, int) =
  ## Calculates the best rational approximation of `x`,
  ## where the denominator is smaller than `n`
  ## (default is the largest possible `int` for maximal resolution),
  ##
  ## The algorithm is from `toRational` of std/rationals,
  ## but raises ValueError or OverflowDefect if x is NaN or Infinity.
  ##
  ##  .. hint:: due to lack of arbitrary length integers,
  ##   its accuracy is not as high as Python's

  self.as_integer_ratio_check()
  let
    self_neg = self < 0.0
    # if not doing so, negative values
    # like `-0.875` even doesn't returns `(-7, 8)`
    abs_self =
      if self_neg: -self
      else: self
  var
    m11, m22 = 1
    m12, m21 = 0
    ai = int(abs_self)
    x = abs_self
  while m21 * ai + m22 <= n:
    swap m12, m11
    swap m22, m21
    m11 = m12 * ai + m11
    m21 = m22 * ai + m21
    if x == float(ai): break # division by zero
    x = 1 / (x - float(ai))
    if x > float(high(int32)): break # representation failure
    ai = int(x)
  if self_neg:
    m11 = -m11
  result = (m11, m21)

func checked_as_integer_ratio*(self: float): (int, int) =
  ## EXT.
  ## like `as_integer_ratio`_ but
  ## raises OverflowDefect when cannot represent accurately.
  self.as_integer_ratio_check()
  var (float_part, exponent) = frexp(self)
  for _ in 0..299:
    if float_part == floor(float_part):
      break
    float_part *= 2.0
    exponent.dec
  #[ self == float_part * 2**exponent exactly and float_part is integral.
     If FLT_RADIX != 2, the 300 steps may leave a tiny fractional part
     to be truncated by PyLong_FromDouble().]#
  var numerator, denominator, py_exponent: int
  numerator = int float_part
  denominator = 1
  py_exponent = abs exponent

  # fold in 2**exponent
  if exponent > 0:
    numerator = checkedShl(numerator, py_exponent)
  else:
    denominator = checkedShl(denominator, py_exponent)
  result = (numerator, denominator)

