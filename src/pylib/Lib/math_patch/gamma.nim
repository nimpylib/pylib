
#[
 The original C code, copyright, license, and constants are from
 [Cephes](http://www.netlib.org/cephes)'s cprob/gamma.c
 The implementation follows the original, but has been modified for Nim.

 ```
 Copyright 1984, 1987, 1989, 1992, 2000 by Stephen L. Moshier

 Some software in this archive may be from the book _Methods and Programs for Mathematical Functions_ (Prentice-Hall or Simon & Schuster International, 1989) or from the Cephes Mathematical Library, a commercial product. In either event, it is copyrighted by the author. What you see here may be used freely but it comes with no support or guarantee.

 Stephen L. Moshier
 moshier@na-net.ornl.gov
 ```
]#

import std/math
import ./consts
import ./sinpi
from ./polevl import polExpd0

func smallApprox[T: SomeFloat](x, z: T): T =
  z / ((1.0+( EULER*x )) * x)

func stirlingApprox[T: SomeFloat](x: T): T =
  ## Evaluates the gamma function using Stirling's formula.
  ## The polynomial is valid for 33 <= x <= 172
  const MAX_STIRLING = 143.01608

  var w, y: T
  w = 1.0 / x
  w = w.polExpd0 [
    1.0,
    0.08333333333334822,
    0.0034722222160545866,
    -0.0026813261780578124,
    -0.00022954996161337813,
    0.0007873113957930937,
  ]
  y = exp(x)

  if x > MAX_STIRLING: # Avoid overflow in pow()
    let v = pow(x, ( 0.5*x ) - 0.25)
    y = v * (v/y)
  else:
    y = pow(x, x-0.5) / y
  return SQRT_TWO_PI * y * w


func isNegInteger(normX: SomeFloat): bool =
  floor(normX) == normX and normX < 0


func gamma*[T: SomeFloat](x: T): T =
  var z: T
  let fc = classify(x)
  if fc == fcNan or fc == fcNegInf or x.isNegInteger:
    return NaN
  if x == 0.0:
    if fc == fcNegZero:
      return NINF
    return PINF
  if x > 171.61447887182298:
    return PINF
  if x < -170.5674972726612:
    return 0.0
  var p, q: T
  q = abs(x)
  if q > 33.0:
    if x >= 0.0:
      return stirlingApprox(x)
    p = floor(q)

    # Check whether `x` is even...
    let sign =
      if (p.int and 1) == 0: -1.0
      else: 1.0

    z = q - p;
    if z > 0.5:
      p += 1.0
      z = q - p

    z = q * sinpi(z)
    if z == 0.0:
      return sign * PINF
    return sign * PI / ( abs(z)*stirlingApprox(q) )

  # Reduce `x`...
  z = 1.0;
  var x = x
  while x >= 3.0:
    x -= 1.0
    z *= x

  while x < 0.0:
    if x > -1.0e-9:
      return smallApprox(x, z)
    z /= x
    x += 1.0

  while x < 2.0:
    if x < 1.0e-9:
      return smallApprox(x, z)
    z /= x
    x += 1.0

  if x == 2.0:
    return z

  x -= 2.0

  # here `x` is in (0.0, 1.0)

  p = x.polExpd0 [
    9.99999999999999996796E-1,
    0.4942148268014971,
    0.20744822764843598,
    0.04763678004571372,
    0.010421379756176158,
    0.0011913514700658638,
    0.00016011952247675185,
  ]
  q = x.polExpd0 [
    1.00000000000000000320E0,
    0.0714304917030273,
    -0.23459179571824335,
    0.035823639860549865,
    0.011813978522206043,
    -0.004456419138517973,
    0.0005396055804933034,
    -0.000023158187332412014,
  ]
  return z * p / q
