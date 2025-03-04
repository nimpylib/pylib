
import std/fenv

from ../Lib/math_impl/isX import isfinite
import ../pyconfig/pycore/pymath/short_float_repr
import ./round/no_ndigit
export no_ndigit.round

const weirdTarget = defined(nimscript) or defined(js)
when not weirdTarget and PY_SHORT_FLOAT_REPR:
  import ./round/PY_SHORT_FLOAT_REPR as impl  # not support JS yet
else:
  import ./round/NOT_PY_SHORT_FLOAT_REPR as impl

type F = float
proc round*(x: F, ndigit: int): F =
  ##[ translated from CPython/Objects/floatobject.c:double_round
   rounds a finite double to the closest multiple of
   10**-ndigits; here ndigits is within reasonable bounds (typically, -308 <=
   ndigits <= 323).  Returns a Python float, or sets a Python error and
   returns NULL on failure (OverflowError and memory errors are possible

   .. hint::
     variant whose `F` is `float32` is not implemented,
       and won't be unless https://netlib.org/fp/ftoa.c is implemented (
       none as of 2025-02-17)
   ]##
  if not x.isfinite:
    return x

  #[ Deal with extreme values for ndigits. For ndigits > NDIGITS_MAX, x
     always rounds to itself.  For ndigits < NDIGITS_MIN, x always
     rounds to +-0.0.  Here 0.30103 is an upper bound for log10(2). ]#
  const
    NDIGITS_MAX = int (F.mantissaDigits-F.minExponent) * 0.30103
    NDIGITS_MIN = -int (F.maxExponent + 1) * 0.30103

  if ndigit > NDIGITS_MAX: x
  elif ndigit < NDIGITS_MIN: 0.0 * x  # return 0.0, but with sign of x
  else: impl.round x, ndigit
