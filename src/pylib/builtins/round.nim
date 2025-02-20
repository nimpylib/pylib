
import std/fenv
import std/math   # math.round, classify, FloatClass
from ../Lib/math_impl/isX import isfinite
import ./private/pycore_pymath

template chkAsPy[F](x: F) =
  ## used to keep along with Python's error handle
  ## check if x can be converted to PyLong
  template err(f) = raise newException(ValueError, "cannot convert float " & f & " to integer")
  case x.classify
  of fcNan: err "NaN"
  of fcInf, fcNegInf: err "infinity"
  else: discard

func round*[F: SomeFloat](x: F): F =
  ## if two multiples are equally close, rounding is done toward the even choice
  ##   a.k.a.round-to-even
  ## 
  ## .. hint:: Nim's `round` in `std/math` just does like C's round
  ## 
  runnableExamples:
    assert round(6.5) == 6
    assert round(7.5) == 8
  result = math.round(x)
  if abs(x-result) == 0.5:
    # halfway case: round to even
    result = 2.0*round(x/2.0)

    # return PyLong_FromDouble....
    result.chkAsPy
const weirdTarget = defined(nimscript) or defined(js)
when not weirdTarget and PY_SHORT_FLOAT_REPR:
  import ./round_PY_SHORT_FLOAT_REPR as impl  # not support JS yet
else:
  import ./round_NOT_PY_SHORT_FLOAT_REPR as impl

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
