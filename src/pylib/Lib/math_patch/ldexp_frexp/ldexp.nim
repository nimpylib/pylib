

import ./consts, ./assertIsInfinite, ./normalize,
  ./toWords, ./fromWords,
  ./exponent
from std/math import isnan, copysign

const
  TWO52_INV = 2.220446049250313e-16 ##\
  ## 1/(1<<52) = 1/(2**52) = 1/4503599627370496


proc ldexpImpl(frac: float, exp: int): float =
  if (
    exp == 0 or
    frac == 0.0 or # handles +-0
    isnan( frac ) or
    isInfinite( frac )
  ):
    return frac
  # Normalize the input fraction:
  let tup = normalize( frac )
  let frac = tup[ 0 ]
  var exp = exp.float
  exp += tup[ 1 ].float

  # Extract the exponent from `frac` and add it to `exp`:
  exp += exponent( frac ).float

  # Check for underflow/overflow...
  if ( exp < MIN_SUBNORMAL_EXPONENT ):
    return copysign( 0.0, frac )

  if exp > MAX_EXPONENT:
    if frac < 0.0:
      return NegInf
    return Inf

  # Check for a subnormal and scale accordingly to retain precision...
  let m =
    if exp <= MAX_SUBNORMAL_EXPONENT:
      exp += 52
      TWO52_INV
    else:
      1.0

  # Split the fraction into higher and lower order words:
  let WORDS = toWords( frac )
  type UI = uint32
  var high: UI
  high = WORDS[ 0 ]
  
  # Clear the exponent bits within the higher order word:
  high = high and CLEAR_EXP_MASK.UI
  
  # Set the exponent bits to the new exponent:
  high = high or (UI(exp+BIAS) shl 20)

  # Create a new floating-point number:
  return m * fromWords( high, WORDS[ 1 ] )

func ldexp*(frac: float, exp: int): float =
  {.noSideEffect.}:  # XXX: TODO
    ldexpImpl frac, exp
  
when isMainModule and defined(js):
  when defined(es6):
    {.error: "TODO".}
  else:
    proc jsldexp( frac: float, exp: cint ): float{.exportc: "ldexp".} = ldexp(frac, exp.int)
    {.emit: "module.exports = ldexp;".}
