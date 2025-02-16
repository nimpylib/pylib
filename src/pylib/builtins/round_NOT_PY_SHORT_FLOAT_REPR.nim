

import std/math   # math.round
from ../Lib/math_impl/isX import isfinite

proc round*(x: float, ndigits: int): float =
  ##[ fallback version, to be used when correctly rounded binary<->decimal
   conversions aren't available]##
  var
    pow1: cdouble
    pow2: cdouble
    y: cdouble
  if ndigits >= 0:
    if ndigits > 22:
      #  pow1 and pow2 are each safe from overflow, but
      #                pow1*pow2 ~= pow(10.0, ndigits) might overflow
      pow1 = pow(10.0, cdouble(ndigits - 22))
      pow2 = 1e22
    else:
      pow1 = pow(10.0, cdouble(ndigits))
      pow2 = 1.0
    y = (x * pow1) * pow2
    #  if y overflows, then rounded value is exactly x
    if not isfinite(y):
      return x
  else:
    pow1 = pow(10.0, cdouble -ndigits)
    pow2 = 1.0
    ##  unused; silences a gcc compiler warning
    y = x / pow1
  result = math.round(y)
  if abs(y - result) == 0.5:
    result = 2.0 * math.round(y / 2.0)
  if ndigits >= 0:
    result = (result / pow2) / pow1
  else:
    result = result * pow1
  #  if computation resulted in overflow, raise OverflowError
  if not isfinite(result):
    raise newException(OverflowDefect, "overflow occurred during round")
