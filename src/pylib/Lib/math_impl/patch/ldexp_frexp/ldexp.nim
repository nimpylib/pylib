

import  ./assertIsInfinite, ./normalize,
  ./exponent

import ../inWordUtilsMapper

wu_import consts
wu_import toWords
wu_import fromWords

from std/math import isnan, copysign

const
  TWO52_INV = 2.220446049250313e-16 ##\
  ## 1/(1<<52) = 1/(2**52) = 1/4503599627370496

func ldexp*[F: SomeFloat](frac: F, exp: int): F =
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
  var exp = exp.F
  exp += tup[ 1 ].F

  # Extract the exponent from `frac` and add it to `exp`:
  exp += exponent( frac ).F

  # Check for underflow/overflow...
  if ( exp < MIN_SUBNORMAL_EXPONENT(F) ):
    return copysign( 0.0, frac )

  if exp > MAX_EXPONENT F:
    if frac < 0.0:
      return NegInf
    return Inf

  # Check for a subnormal and scale accordingly to retain precision...
  let m =
    if exp <= MAX_SUBNORMAL_EXPONENT F:
      exp += MantissaDigits F
      TWO52_INV
    else:
      1.0

  # Split the fraction into higher and lower order words:
  let WORDS = toWords( frac )
  var high = WORDS[ 0 ]
  type UI = typeof high
  
  # Clear the exponent bits within the higher order word:
  high = high and CLEAR_EXP_MASK[F].UI
  
  # Set the exponent bits to the new exponent:
  high = high or (UI(exp+BIAS F) shl 20)

  # Create a new floating-point number:
  return m * fromWords( high, WORDS[ 1 ] )

when isMainModule and defined(js):
  func jsldexp( frac: float, exp: cint ): float{.used, exportc: "ldexp".} = ldexp(frac, exp.int)
  when defined(es6):
    # for test
    {.emit: """export {ldexp};""".}
  else:
    {.emit: "module.exports = ldexp;".}
