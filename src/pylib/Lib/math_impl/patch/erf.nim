
# CPython's manual implememtation for erf and erfc was removed since
# `gh-101678: refactor the math module to use special functions from c11
# (...GH-101679)`


#[ the following is CPython's comment
 Implementations of the error function erf(x) and the complementary error
 function erfc(x).
 Method: we use a series approximation for erf for small x, and a continued
 fraction approximation for erfc(x) for larger x;
 combined with the relations erf(-x) = -erf(x) and erfc(x) = 1.0 - erf(x),
 this gives us erf(x) and erfc(x) for all x.
 The series expansion used is:
    erf(x) = x*exp(-x*x)/sqrt(pi) * [
                   2/1 + 4/3 x**2 + 8/15 x**4 + 16/105 x**6 + ...]
 The coefficient of x**(2k-2) here is 4**k*factorial(k)/factorial(2*k).
 This series converges well for smallish x, but slowly for larger x.
 The continued fraction expansion used is:
    erfc(x) = x*exp(-x*x)/sqrt(pi) * [1/(0.5 + x**2 -) 0.5/(2.5 + x**2 - )
                            3.0/(4.5 + x**2 - ) 7.5/(6.5 + x**2 - ) ...]
 after the first term, the general term has the form:
    k*(k-0.5)/(2*k+0.5 + x**2 - ...).
 This expansion converges fast for larger x, but convergence becomes
 infinitely slow as x approaches 0.0.  The (somewhat naive) continued
 fraction evaluation algorithm used below also risks overflow for large x;
 but for large x, erfc(x) == 0.0 to within machine precision.  (For
 example, erfc(30.0) is approximately 2.56e-393).
 Parameters: use series expansion for abs(x) < ERF_SERIES_CUTOFF and
 continued fraction expansion for ERF_SERIES_CUTOFF <= abs(x) <
 ERFC_CONTFRAC_CUTOFF.  ERFC_SERIES_TERMS and ERFC_CONTFRAC_TERMS are the
 numbers of terms to use for the relevant expansions.
]#

from std/math import exp, isNaN

const
  sqrtpi = 1.772453850905516027298167483341145182798

const
  ERF_SERIES_CUTOFF = 1.5
  ERF_SERIES_TERMS = 25
  ERFC_CONTFRAC_CUTOFF = 30.0
  ERFC_CONTFRAC_TERMS = 50

proc m_erf_series[F](x: F): F =
  ##
  ## Error function, via power series.
  ## Given a finite float x, return an approximation to erf(x).
  ## Converges reasonably fast for small x.
  ##
  let x2 = x * x
  var
    acc = 0.0
    fk = cast[F](ERF_SERIES_TERMS) + 0.5
  for i in 0..<ERF_SERIES_TERMS:
    acc = 2.0 + x2 * acc / fk
    fk -= 1.0
  # Even if the exp call affect errno, `erf` don't check for it;
  #   see m_erfc_contfrac for more.
  result = acc * x * exp(-x2) / sqrtpi

proc m_erfc_contfrac[F](x: F): F =
  ##
  ## Complementary error function, via continued fraction expansion.
  ## Given a positive float x, return an approximation to erfc(x).  Converges
  ## reasonably fast for x large (say, x > 2.0), and should be safe from
  ## overflow if x and nterms are not too large.  On an IEEE 754 machine, with x
  ## <= 30.0, we're safe up to nterms = 100.  For x >= 30.0, erfc(x) is smaller
  ## than the smallest representable nonzero float.
  ##
  if x >= ERFC_CONTFRAC_CUTOFF:
    return 0.0
  let x2 = x * x
  var
    a = 0.0
    da = 0.5
    p = 1.0
    p_last = 0.0
    q = da + x2
    q_last = 1.0
  var
    temp: F
    b: F
  for i in 0..<ERFC_CONTFRAC_TERMS:
    a += da
    da += 2.0
    b = da + x2
    temp = p
    p = b * p - a * p_last
    p_last = temp
    temp = q
    q = b * q - a * q_last
    q_last = temp

  ## the following is from CPython's, but we don't check errno.
  #  Issue #8986: On some platforms, exp sets errno on underflow to zero;
  #        save the current errno value so that we can restore it later.

  result = p / q * x * exp(-x2) / sqrtpi


proc erf*[F: SomeFloat](x: F): F =
  ##  Error function erf(x), for general x
  if isNaN(x):
    return x
  let absx = abs(x)
  if absx < ERF_SERIES_CUTOFF:
    m_erf_series(x)
  else:
    let cf = m_erfc_contfrac(absx)
    if x > 0.0: 1.0 - cf else: cf - 1.0

proc erfc*[F: SomeFloat](x: F): F =
  ##  Complementary error function erfc(x), for general x.
  if isNaN(x):
    return x
  let absx = abs(x)
  if absx < ERF_SERIES_CUTOFF:
    1.0 - m_erf_series(x)
  else:
    let cf = m_erfc_contfrac(absx)
    if x > 0.0: cf else: 2.0 - cf

when isMainModule and defined(js) and defined(es6):  # for test
  func erf*(x: float): float{.exportc.} = erf[float](x)
  func erfc*(x: float): float{.exportc.} = erfc[float](x)
  {.emit: """export {erf, erfc};""".}
