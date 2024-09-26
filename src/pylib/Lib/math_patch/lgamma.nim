
##[
## Notice

This module was hand-translated from [FreeBSD's lgamma](
https://svnweb.freebsd.org/base/release/12.2.0/lib/msun/src/e_lgamma_r.c) implementation;

and with some modification:

- no static data is used, so each function is thread-safe.


The following copyright, license, and long comment were part of
  the original implementation available as part of
  FreeBSD

```
Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.

Developed at SunPro, a Sun Microsystems, Inc. business.
Permission to use, copy, modify, and distribute this
software is freely granted, provided that this notice
is preserved.
```

]##


from std/math import ln, classify, FloatClass, Pi
import ./trunc, ./sinpi, ./consts
from ./polevl import polExpd0
from ./err import mapRaiseGammaErr, GammaError

export GammaError

const
  WC = 4.18938533204672725052e-01    ##  0x3FDACFE390C97D69

  YMIN = 1.461632144968362245

  TWO56 = 72057594037927936'i64 ##  2**56

  TINY = 1.3877787807814457e-17

  TC = 1.46163214496836224576e+00  ##  0x3FF762D86356BE3F
  TF = -1.21486290535849611461e-01  ##  0xBFBF19B9BCC38A42

  TT = -3.63867699703950536541e-18  ##  0xBC50C7CAA48A971F
                                    ##   => `TT = -(tail of TF)`

proc polyvalA1[F](x: F): F =
  x.polExpd0 [
    7.72156649015328655494e-02,
    0.06735230105312927,
    0.007385550860814029,
    0.0011927076318336207,
    0.00022086279071390839,
    0.000025214456545125733,
  ]

proc polyvalA2[F](x: F): F =
  x.polExpd0 [
    3.22467033424113591611e-01,
    0.020580808432516733,
    0.0028905138367341563,
    0.0005100697921535113,
    0.00010801156724758394,
    0.000044864094961891516,
  ]

proc polyvalR[F](x: F): F =
  x.polExpd0 [
   1.0,
   1.3920053346762105,
   0.7219355475671381,
   0.17193386563280308,
   0.01864591917156529,
   0.0007779424963818936,
   0.000007326684307446256,
  ]

proc polyvalS[F](x: F): F =
  x.polExpd0 [
    -7.72156649015328655494e-02,  #  0xBFB3C467E37DB0C8
    0.21498241596060885,
    0.325778796408931,
    0.14635047265246445,
    0.02664227030336386,
    0.0018402845140733772,
    0.00003194753265841009,
  ]

proc polyvalT1[F](x: F): F =
  x.polExpd0 [
    4.83836122723810047042e-01,  #  0x3FDEF72BC8EE38A2
    -0.032788541075985965,
    0.006100538702462913,
    -0.0014034646998923284,
    0.00031563207090362595,
  ]

proc polyvalT2[F](x: F): F =
  x.polExpd0 [
    -1.47587722994593911752e-01, #  0xBFC2E4278DC6C509
    0.01797067508118204,
    -0.0036845201678113826,
    0.000881081882437654,
    -0.00031275416837512086,
  ]

proc polyvalT3[F](x: F): F =
  x.polExpd0 [
    6.46249402391333854778e-02, #  0x3FB08B4294D5419B
    -0.010314224129834144,
    0.0022596478090061247,
    -0.0005385953053567405,
    0.0003355291926355191,
  ]

proc polyvalU[F](x: F): F =
  x.polExpd0 [
    -7.72156649015328655494e-02, #  0xBFB3C467E37DB0C8
    0.6328270640250934,
    1.4549225013723477,
    0.9777175279633727,
    0.22896372806469245,
    0.013381091853678766,
  ]

proc polyvalV[F](x: F): F =
  x.polExpd0 [
    1.0,
    2.4559779371304113,
    2.128489763798934,
    0.7692851504566728,
    0.10422264559336913,
    0.003217092422824239,
  ]

proc polyvalW[F](x: F): F =
  x.polExpd0 [
    0.08333333333333297,
    -0.0027777777772877554,
    0.0007936505586430196,
    -0.00059518755745034,
    0.0008363399189962821,
    -0.0016309293409657527,
  ]

func lgamma*[F: SomeFloat](x: F, res: var F): GammaError =
  ## currently do not return geOverFlow, geUnderFlow
  var flg: int32
  var p, q: F
  var w, y, z, r: F

  template ret(st; rt=geOk) =
    res = st
    return rt
  # purge +-Inf, NaN
  let fc = classify(x)
  if fc == fcNan:
    ret x
  if fc == fcNegInf:
    ## R/CPython/C's lgamma(-Inf) returns Inf
    ret Pinf, geGotNegInf
  if fc == fcInf:
    ret Pinf
  if x == 0.0:
    ret Pinf, geDom
  var
    xc = x
    isNegative = false
  if xc < 0.0:
    isNegative = true
    xc = -xc

  # purge tiny argument
  # If |x| < 2**-56, return -ln(|x|)
  if xc < TINY:
    ret -ln(xc)

  var t, nadj: F
  # purge negative integers and start evaluation for other x < 0 
  if isNegative:
    # If |x| > maxSafeInteger, then x lost
    # the accuracy of unit digit, so it becomes a -integer
    # XXX: the original C uses: /* |x|>=2**52, must be -integer */
    #  where the 2**52 comes from?
    if xc > F.maxSafeInteger:
      ret NINF, geZeroCantDetSign
    t = sinpi(xc)
    if t == 0.0:  # -integer
      ret Pinf, geDom
    nadj = ln(Pi / abs(t * xc))

  # purge 1 and 2
  if xc == 1.0 or xc == 2.0:
    ret 0.0

  # for x < 2.0
  if xc < 2.0:
    if xc <= 0.9:  # lgamma(x) = lgamma(x+1)-log(x)
      r = -ln(xc)
      if xc >= (YMIN - 1.0 + 0.27):
        ##  0.7316 <= x <=  0.9
        y = 1.0 - xc
        flg = 0
      elif xc >= (YMIN - 1.0 - 0.27):
        ##  0.2316 <= x < 0.7316
        y = xc - (TC - 1.0)
        flg = 1
      else:
        ##  0 < x < 0.2316
        y = xc
        flg = 2
    else:
      r = 0.0
      if xc >= (YMIN + 0.27):
        ##  1.7316 <= x < 2
        y = 2.0 - xc
        flg = 0
      elif xc >= (YMIN - 0.27):
        ##  1.2316 <= x < 1.7316
        y = xc - TC
        flg = 1
      else:
        ##  0.9 < x < 1.2316
        y = xc - 1.0
        flg = 2
    var p1, p2, p3: F
    case flg
    of 0:
      z = y * y
      p1 = polyvalA1(z)
      p2 = z * polyvalA2(z)
      p = (y * p1) + p2
      r += (p - (0.5 * y))
    of 1:
      z = y * y
      w = z * y
      p1 = polyvalT1(w)
      p2 = polyvalT2(w)
      p3 = polyvalT3(w)
      p = (z * p1) - (TT - (w * (p2 + (y * p3))))
      r += (TF + p)
    of 2:
      p1 = y * polyvalU(y)
      p2 = polyvalV(y)
      r += (-(0.5 * y)) + (p1 / p2)
    else: discard
  elif xc < 8.0:
    ##  2 <= x < 8
    flg = uncheckedTruncToInt[typeof(flg)](xc)
    y = xc - F flg
    p = y * polyvalS(y)
    q = polyvalR(y)
    r = (0.5 * y) + (p / q)
    z = 1.0
    ##  gammaln(1+s) = ln(s) + gammaln(s)
    if flg in 3..7:
      for i in countdown(flg-1, 2):
        z = z * (y + F i)
      r += ln(z)
  elif xc < F TWO56:
    ##  8 <= x < 2**56
    t = ln(xc)
    z = 1.0 / xc
    y = z * z
    w = WC + (z * polyvalW(y))
    r = ((xc - 0.5) * (t - 1.0)) + w
  else:
    ##  2**56 <= x <= Inf
    r = xc * (ln(xc) - 1.0)
  if isNegative:
    r = nadj - r
  ret r

func lgamma*[F: SomeFloat](x: F): F =
  ##[ Evaluates the natural logarithm of the absolute value of gamma function.

  The following was formatted as Nim-Favor Markdown from
  [FreeBSD `lgamma` source](https://svnweb.freebsd.org/base/release/12.2.0/lib/msun/src/e_lgamma_r.c)
  with some minor amendment.
  

  ## Method:

  ### 1. Argument Reduction for 0 < x <= 8
      ```
      Since gamma(1+s)=s*gamma(s), for x in [0,8], we may
      reduce x to a number in [1.5,2.5] by
              lgamma(1+s) = log(s) + lgamma(s)
      for example,
              lgamma(7.3) = log(6.3) + lgamma(6.3)
                          = log(6.3*5.3) + lgamma(5.3)
                          = log(6.3*5.3*4.3*3.3*2.3) + lgamma(2.3)
      ```

  ### 2. A polynomial approximation of lgamma
      Create a polynomial approximation of lgamma around its
      minimun `ymin=1.461632144968362245` to maintain monotonicity.

      ```
      On [ymin-0.23, ymin+0.27] (i.e., [1.23164,1.73163]), use
              Let z = x-ymin;
              lgamma(x) = -1.214862905358496078218 + z^2*poly(z)
      where
              poly(z) is a 14 degree polynomial.
      ```

  ### 3. Rational approximation in the primary interval `[2,3]`

```
      We use the following approximation:  
              s = x-2.0;
              lgamma(x) = 0.5*s + s*P(s)/Q(s)
      with accuracy
              |P/Q - (lgamma(x)-0.5s)| < 2**-61.71
      Our algorithms are based on the following observation

                                  zeta(2)-1    2    zeta(3)-1    3
      lgamma(2+s) = s*(1-Euler) + --------- * s  -  --------- * s  + ...
                                      2                 3
```

      where `Euler = 0.5771...` is the Euler constant, which is very
      close to 0.5.

  ### 4. For x>=8, ...

```
      For x>=8, we have
        lgamma(x) ~ (x-0.5)log(x)-x+0.5*log(2pi)+1/(12x)-1/(360x**3)+....

      (better formula:
         lgamma(x) ~ (x-0.5)*(log(x)-1)-.5*(log(2pi)-1) + ...)

      Let z = 1/x, then we approximation
              f(z) = lgamma(x) - (x-0.5)(log(x)-1)
      by
                                  3       5             11
              w = w0 + w1*z + w2*z  + w3*z  + ... + w6*z
      where
              |w - f(z)| < 2**-58.74
```

  ### 5. For negative x, ...

      ```
      For negative x, since (G is gamma function)
              -x*G(-x)*G(x) = pi/sin(pi*x),
      we have
              G(x) = pi/(sin(pi*x)*(-x)*G(-x))
      since G(-x) is positive, sign(G(x)) = sign(sin(pi*x)) for x<0
      Hence, for x<0, signgam = sign(sin(pi*x)) and
              lgamma(x) = log(|Gamma(x)|)
                        = log(pi/(|x*sin(pi*x)|)) - lgamma(-x);
      ```

      .. note:: one should avoid computing `pi*(-x)` directly in the
            computation of `sin(pi*(-x))` but using `sinpi(-x)`

  ##  Special Cases
    ```
              lgamma(2+s) ~ s*(1-Euler) for tiny s
              lgamma(1) = lgamma(2) = 0
              lgamma(x) ~ -log(|x|) for tiny x
              lgamma(0) = lgamma(neg.integer) = inf and raise divide-by-zero
              lgamma(inf) = inf
              lgamma(-inf) = inf  # see below
    ```
    For `lgamma(-inf)`,
    - some implementations, like CPython's math, R
    and C/C++ returns +inf;
     which is not suitable, as gamma(x) where x < about -200
     is always truncated to 0.0 at ieee754 float domain.
     This behavior was said for bug compatible with C99, and is readlly documented by [POSIX man](
      https://www.man7.org/linux/man-pages/man3/lgamma.3.html
     ) and [cppreference.com](https://en.cppreference.com/w/c/numeric/math/lgamma)
    - While others like `scipy.special.gammaln`, Go's `math.Lgamma`, returns 

    In my option, `ln(|gamma(-oo)|) -[ieee754 float trunc]-> ln(0+) -> -inf`
  
    But in this function it returns +inf to keep consistent with Python,

  ]##

  runnableExamples:
    assert lgamma(1.0) == 0.0
    assert lgamma(Inf) == Inf
    assert lgamma(NaN) == NaN
  mapRaiseGammaErr x.lgamma result

func stdlibJsLgamma*[F: SomeFloat](x: F): F{.raises: [].} =
  discard x.lgamma result

func rLgamma*[F: SomeFloat](x: F): F{.raises: [].} = stdlibJsLgamma(x)

func scipyGammaLn*[F: SomeFloat](x: F): F{.raises: [].} =
  ## .. note:: this returns -inf for -inf argument, and raises no math error,
  ##   just like `scipy.special.gammaln`
  let err = x.lgamma result
  if err == geGotNegInf:
    return NINF

when isMainModule and defined(js) and defined(es6):  # for test
  func gammaln*(x: float): float{.exportc.} = stdlibJsLgamma(x)
  {.emit: """export {gammaln};""".}
