
#[
 The original C code, copyright, license, and constants are from
 [Cephes](http://www.netlib.org/cephes)'s cprob/gamma.c
 The implementation follows the original, but has been modified a lot
 for Nim and add support for Python/R/stdlib-js's behaviors.

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
from ./trunc import uncheckedTruncToInt
from ./polevl import polExpd0
from ./err import raiseDomainErr, raiseRangeErr

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


const
  MAX_GAMMA_X = 171.61447887182298
  MIN_GAMMA_X = -170.5674972726612

type GammaError* = enum
  geOk
  geInfDiscont = "x in {0, -1, -2, ...}" ##[ when .
Infinity discontinuity,
which shall produce `Complex Infinity` in SymPy and
means domain error]##
  geOverFlow = "x > " & $MAX_GAMMA_X & ", result overflow as inf"
  geUnderFlow = "x < " & $MIN_GAMMA_X & ", result underflow as `-0.0` or `0.0`."
  geZeroCantDetSign = "`x < -maxSafeInteger`(exclude -inf), " &
    "can't detect result's sign"   ## `x` losing unit digit, often not regard as an error
  geGotNegInf = "x == -inf"  ## this is made as a enumerate item as different languages'
                             ## implementation has different treatment towards -inf


func isEven[F: SomeFloat](positive: F): int =
  ## check if a positive float intpart is even.
  ## returns:
  ##  -1 if cannot detect, 0/1 for yes/no
  assert positive > 0.0
  if positive < F.maxSafeInteger:
    # maxSafeInteger is less than BiggestInt.high
    cast[int]((cast[BiggestInt](positive) and 1))
  else: -1


func gammaImpl[T: SomeFloat](x: T, res: var T, fc: FloatClass): GammaError =
  template ret(st; rt=geOk) =
    ## set to res & return
    res = st
    return rt
  case fc
  of fcNan:    ret NaN
  of fcNegInf: ret 0.0, geGotNegInf
  elif x == 0.0 or x.isNegInteger:
    # XXX: though in ieee754 there're both `-0.0` and `0.0`,
    #  we just come along with mainstream like SymPy, R, etc and
    #  simply return NaN and introduce domain error.
    ret NaN, geInfDiscont
  elif x > MAX_GAMMA_X:
    ret PINF, geOverFlow
  else: discard

  # now `x` is a normal, non-zero, non-negative-integer float

  template chkGetSign(ax: T): T =
    ## used for `gamma` with negative value,
    ## panic if `ax` is not positive.
    ##
    ## if `ax` is even, gets -1.0; if odd, gets 1.0;
    ## And makes outer functions returns geZeroCantDetSign if cannot detect
    let even: int = ax.isEven
    if even == -1:
      ret 0.0, geZeroCantDetSign
    block:
      if even == 1: -1.0
      else: 1.0
  let ax = abs(x)
  var sign: float
  if x < MIN_GAMMA_X:
    # `\lim_{x->-\infinity} |\Gamma(x)| = 0`, but not gamma(x) itself.
    sign = chkGetSign ax
    ret sign * 0.0, geUnderFlow
  var z: T
  var p, q: T
  let isPositive = x > 0.0
  var ix: int
  if ax > 33.0:
    if isPositive:
      ret stirlingApprox(x)
    p = floor(ax)

    sign = chkGetSign p

    # calcuate the delta between nearest integer
    z = ax - p
    if z > 0.5:
      p += 1.0
      z = ax - p
    # now z is in (-0.5, 0.5]

    z = ax * sinpi(z)
    if z == 0.0: ret sign * PINF
    else: ret sign * PI / ( abs(z)*stirlingApprox(q) )
  elif isPositive:
    # then x is in `(0.0, 33.0]`
    template asInt(x: T, res: var int): bool =
      res = uncheckedTruncToInt[int](x)
      # NIM-BUG: using cast above results in rt-err when JS in `math.fac`
      res.T == x
    const
      NGAMMA_INTEGRAL =  ## length of `fac`'s inner table
        when sizeof(int) == 2: 5
        elif sizeof(int) == 4: 13
        else: 21
    if x.asInt(ix) and ix < NGAMMA_INTEGRAL:
      # fast-path: `gamma(x) = (x-1)!`, when x is positive integer.
      ret T fac(ix-1)

  # Reduce `x`...
  z = 1.0;
  var x = x
  while x >= 3.0:
    x -= 1.0
    z *= x

  while x < 0.0:
    if x > -1.0e-9:
      ret smallApprox(x, z)
    z /= x
    x += 1.0

  while x < 2.0:
    if x < 1.0e-9:
      ret smallApprox(x, z)
    z /= x
    x += 1.0

  if x == 2.0:
    ret z

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
  ret z * p / q

func gamma*[T: SomeFloat](x: T, res: var T): GammaError =
  ## a more error friendly version of gamma
  gammaImpl x, res, classify(x)

func gamma*[F: SomeFloat](x: F): F =
  ## CPython `math.gamma`-like, with error message more detailed.
  runnableExamples:
    template chkValueErr(arg) =
      doAssertRaises ValueError: discard gamma arg
    chkValueErr NegInf
    chkValueErr 0.0
    assert NegInf == 1.0/gamma(-172.5)
  let err = x.gamma result
  case err
  of geOverFlow, geUnderFlow:
    raiseRangeErr $err
  of geInfDiscont, geGotNegInf:
    raiseDomainErr $err
  of geOk, geZeroCantDetSign: discard

func rGamma*[F: SomeFloat](x: F): F{.raises: [].} =
  ## behaviors like R's `gamma` except for this without any warning.
  runnableExamples:
    from std/math import isNaN
    assert isNaN rgamma NegInf
    assert Inf == 1/rgamma(-172.1)  # never returns -0.0
  case x.gamma result
  of geGotNegInf:
    result = NaN
  of geUnderFlow:
    result = 0.0  ## always returns +0.0
  else: discard

func stdlibJsGamma*[F: SomeFloat](x: F): F{.raises: [].} =
  ## behaviors like `@stdlib-js/gamma.js`
  let fc = classify(x)
  case fc
  of fcNegZero: return NINF
  of fcZero: return PINF
  of fcNegInf: return NaN
  else: discard
  discard x.gammaImpl(result, fc)

when isMainModule and defined(js) and defined(es6):  # for test
  func gamma*(x: float): float{.exportc.} = stdlibJsGamma[float](x)
  {.emit: """export {gamma};""".}
