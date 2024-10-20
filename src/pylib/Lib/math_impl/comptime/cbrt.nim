## from https://www.netlib.org/cephes/
##  cmath.tgz cbrt.c
## And
##  single.tgz cbrtf.c
##
## Cube root
##
##  DESCRIPTION:
##
##  Returns the cube root of the argument, which may be negative.
##
##  Range reduction involves determining the power of 2 of
##  the argument.  A polynomial of degree 2 applied to the
##  mantissa, and multiplication by the cube root of 1, 2, or 4
##  approximates the root to within about 0.1%.  Then Newton's
##  iteration is used three times to converge to an accurate
##  result.
##
##
##
##  ACCURACY:
##
##                       Relative error:
##  arithmetic   domain     # trials      peak         rms
##     DEC        -10,10     200000      1.8e-17     6.2e-18
##     IEEE       0,1e308     30000      1.5e-16     5.0e-17
##
##
## cbrt.c
##
## Cephes Math Library Release 2.8:  June, 2000
## Copyright 1984, 1991, 2000 by Stephen L. Moshier
##
## cbrt.nim
## Copyright litlighilit 2024

const CBRT2 = 1.2599210498948731647672
const CBRT4 = 1.5874010519681994747517
const CBRT2I = 0.79370052598409973737585
const CBRT4I = 0.62996052494743658238361

from std/math import classify, FloatClass

# XXX: std/math.frexp cannot use in VM

from ../frexp import n_frexp
from ../ldexp import n_ldexp

func cbrt*[F: SomeFloat](x: F): F =
  let fc = classify x
  if fc != fcNormal and fc != fcSubNormal:
    return x
  var
    e: int
    sign: int
  result = x
  if x >= 0:
    sign = 1
  else:
    sign = -1
    result = -x
  let z = result
  ##  extract power of 2, leaving
  ##  mantissa between 0.5 and 1
  ##

  result = n_frexp(result, e)
  ##  Approximate cube root of number between .5 and 1,
  ##  peak relative error = 9.2e-6
  ##

  result = (((-(1.3466110473359520655053e-1 * result) + 5.4664601366395524503440e-1) * result -
      9.5438224771509446525043e-1) * result + 1.1399983354717293273738e0) * result +
      4.0238979564544752126924e-1
  ##  exponent divided by 3
  when F is float64:
    const
      c2 = CBRT2
      c4 = CBRT4
  else:
    const
      c2 = CBRT2I
      c4 = CBRT4I

  var rem: int
  if e >= 0:
    rem = e
    e = e div 3
    dec(rem, 3 * e)
    if rem == 1:
      result *= CBRT2
    elif rem == 2:
      result *= CBRT4
  else: # argument less than 1
    e = -e
    rem = e
    e = e div 3
    rem -= 3 * e
    if rem == 1:
      result *= c2
    elif rem == 2:
      result *= c4
    e = -e
  ##  multiply by power of 2

  result = n_ldexp(result, e)
  ##  Newton iteration

  result -= (result - (z / (result * result))) * 0.33333333333333333333
  when F is float64:
    result -= (result - (z / (result * result))) * 0.33333333333333333333
  if sign < 0:
    result = -result
