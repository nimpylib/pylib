

from std/math import frexp, sqrt
from std/fenv import minimumPositiveValue
from ../ldexp import c_ldexp
from ../isX import isinf, isnan
from ./niter_types import toSeq, openarray_Check, dist_checkedSameLen, OpenarrayOrNimIter
from ./private/dl_ops import dl_mul, DoubleLength

proc dl_fast_sum(a: float, b: float): DoubleLength =
  ##  Algorithm 1.1. Compensated summation of two floating-point numbers.
  assert(abs(a) >= abs(b))
  let x = a + b
  let y = (a - x) + b
  return DoubleLength(hi: x , lo: y)

type Py_ssize_t = int
const DBL_MIN = minimumPositiveValue float

proc vector_norm[F](n: Py_ssize_t; vec: var openarray[F]; max: F; found_nan: bool): F {.
    inline.} =
  ##
  ## Given a *vec* of values, compute the vector norm:
  ##
  ##     sqrt(sum(x ** 2 for x in vec))
  ##
  ## The *max* variable should be equal to the largest abs(x).
  ## The *n* variable is the length of *vec*.
  ## If n==0, then *max* should be 0.0.
  ## If an infinity is present in the vec, *max* should be INF.
  ## The *found_nan* variable indicates whether some member of
  ## the *vec* is a NaN.
  ##
  ## To avoid overflow/underflow and to achieve high accuracy giving results
  ## that are almost always correctly rounded, four techniques are used:
  ##
  ##  lossless scaling using a power-of-two scaling factor
  ##  accurate squaring using Veltkamp-Dekker splitting [1]
  ##   or an equivalent with an fma() call
  ##  compensated summation using a variant of the Neumaier algorithm [2]
  ##  differential correction of the square root [3]
  ##
  ## The usual presentation of the Neumaier summation algorithm has an
  ## expensive branch depending on which operand has the larger
  ## magnitude.  We avoid this cost by arranging the calculation so that
  ## abs(csum) is always as large as abs(x).
  ##
  ## To establish the invariant, *csum* is initialized to 1.0 which is
  ## always larger than x**2 after scaling or after division by *max*.
  ## After the loop is finished, the initial 1.0 is subtracted out for a
  ## net zero effect on the final sum.  Since *csum* will be greater than
  ## 1.0, the subtraction of 1.0 will not cause fractional digits to be
  ## dropped from *csum*.
  ##
  ## To get the full benefit from compensated summation, the largest
  ## addend should be in the range: 0.5 <= |x| <= 1.0.  Accordingly,
  ## scaling or division by *max* should not be skipped even if not
  ## otherwise needed to prevent overflow or loss of precision.
  ##
  ## The assertion that hi*hi <= 1.0 is a bit subtle.  Each vector element
  ## gets scaled to a magnitude below 1.0.  The Veltkamp-Dekker splitting
  ## algorithm gives a *hi* value that is correctly rounded to half
  ## precision.  When a value at or below 1.0 is correctly rounded, it
  ## never goes above 1.0.  And when values at or below 1.0 are squared,
  ## they remain at or below 1.0, thus preserving the summation invariant.
  ##
  ## Another interesting assertion is that csum+lo*lo == csum. In the loop,
  ## each scaled vector element has a magnitude less than 1.0.  After the
  ## Veltkamp split, *lo* has a maximum value of 2**-27.  So the maximum
  ## value of *lo* squared is 2**-54.  The value of ulp(1.0)/2.0 is 2**-53.
  ## Given that csum >= 1.0, we have:
  ##     lo**2 <= 2**-54 < 2**-53 == 1/2*ulp(1.0) <= ulp(csum)/2
  ## Since lo**2 is less than 1/2 ulp(csum), we have csum+lo*lo == csum.
  ##
  ## To minimize loss of information during the accumulation of fractional
  ## values, each term has a separate accumulator.  This also breaks up
  ## sequential dependencies in the inner loop so the CPU can maximize
  ## floating point throughput. [4]  On an Apple M1 Max, hypot(*vec)
  ## takes only 3.33 µsec when len(vec) == 1000.
  ##
  ## The square root differential correction is needed because a
  ## correctly rounded square root of a correctly rounded sum of
  ## squares can still be off by as much as one ulp.
  ##
  ## The differential correction starts with a value *x* that is
  ## the difference between the square of *h*, the possibly inaccurately
  ## rounded square root, and the accurately computed sum of squares.
  ## The correction is the first order term of the Maclaurin series
  ## expansion of sqrt(h**2 + x) == h + x/(2*h) + O(x**2). [5]
  ##
  ## Essentially, this differential correction is equivalent to one
  ## refinement step in Newton's divide-and-average square root
  ## algorithm, effectively doubling the number of accurate bits.
  ## This technique is used in Dekker's SQRT2 algorithm and again in
  ## Borges' ALGORITHM 4 and 5.
  ##
  ## The hypot() function is faithfully rounded (less than 1 ulp error)
  ## and usually correctly rounded (within 1/2 ulp).  The squaring
  ## step is exact.  The Neumaier summation computes as if in doubled
  ## precision (106 bits) and has the advantage that its input squares
  ## are non-negative so that the condition number of the sum is one.
  ## The square root with a differential correction is likewise computed
  ## as if in doubled precision.
  ##
  ## For n <= 1000, prior to the final addition that rounds the overall
  ## result, the internal accuracy of "h" together with its correction of
  ## "x / (2.0 * h)" is at least 100 bits. [6] Also, hypot() was tested
  ## against a Decimal implementation with prec=300.  After 100 million
  ## trials, no incorrectly rounded examples were found.  In addition,
  ## perfect commutativity (all permutations are exactly equal) was
  ## verified for 1 billion random inputs with n=5. [7]
  ##
  ## References:
  ##
  ## 1. Veltkamp-Dekker splitting: http://csclub.uwaterloo.ca/~pbarfuss/dekker1971.pdf
  ## 2. Compensated summation:  http://www.ti3.tu-harburg.de/paper/rump/Ru08b.pdf
  ## 3. Square root differential correction:  https://arxiv.org/pdf/1904.09481.pdf
  ## 4. Data dependency graph:  https://bugs.python.org/file49439/hypot.png
  ## 5. https://www.wolframalpha.com/input/?i=Maclaurin+series+sqrt%28h**2+%2B+x%29+at+x%3D0
  ## 6. Analysis of internal accuracy:  https://bugs.python.org/file49484/best_frac.py
  ## 7. Commutativity test:  https://bugs.python.org/file49448/test_hypot_commutativity.py
  ##
  ##
  var max_e: c_int
  if isinf(max):
    return max
  if found_nan:
    return NaN
  if max == 0.0 or n <= 1:
    return max
  var max_e_int: int
  discard frexp(max, max_e_int)
  max_e = c_int max_e_int
  if max_e < -1023:
    #  When max_e < -1023, ldexp(1.0, -max_e) would overflow.
    for e in vec.mitems:
      e = e / DBL_MIN
      #  convert subnormals to normals
    return DBL_MIN * vector_norm(n, vec, max / DBL_MIN, found_nan)
  let scale = c_ldexp(1.0, -max_e)
  assert(max * scale >= 0.5)
  assert(max * scale < 1.0)
  var
    csum: float = 1.0
    frac1: float = 0.0
    frac2: float = 0.0
  var
    pr: DoubleLength
    sm: DoubleLength
  for ori_x in vec:
    assert(isfinite(ori_x) and abs(ori_x) <= max)
    let x = ori_x * scale
    #  lossless scaling
    assert(abs(x) < 1.0)
    pr = dl_mul(x, x)
    #  lossless squaring
    assert(pr.hi <= 1.0)
    sm = dl_fast_sum(csum, pr.hi)
    #  lossless addition
    csum = sm.hi
    frac1 += pr.lo
    #  lossy addition
    frac2 += sm.lo
    #  lossy addition
  var h = sqrt(csum - 1.0 + (frac1 + frac2))
  pr = dl_mul(-h, h)
  sm = dl_fast_sum(csum, pr.hi)
  csum = sm.hi
  frac1 += pr.lo
  frac2 += sm.lo
  let x = csum - 1.0 + (frac1 + frac2)
  h += x / (2.0 * h)
  #  differential correction
  return h / scale

template toFloat(x: float): float = x
template toFloat(x: float32): float = float x

proc math_dist_impl[T](p, q: openarray[T], n: Py_ssize_t): float =
  ## [clinic input]
  ## math.dist
  ##
  ##     p: object
  ##     q: object
  ##     /
  ##
  ## Return the Euclidean distance between two points p and q.
  ##
  ## The points should be specified as sequences (or iterables) of
  ## coordinates.  Both inputs must have the same dimension.
  ##
  ## Roughly equivalent to:
  ##     sqrt(sum((px - qx) ** 2.0 for px, qx in zip(p, q)))
  ## [clinic start generated code]
  ## [clinic end generated code: output=56bd9538d06bbcfe input=74e85e1b6092e68e]
  var diffs = newSeq[float](n)
  var max = 0.0
  var found_nan = false
  {.push boundChecks: off.}
  for i in 0 ..< n:
    let
      px = p[i].toFloat
      qx = q[i].toFloat
    let
      x = abs(px - qx)
    diffs[i] = x
    found_nan = found_nan or isnan(x)
    if x > max:
      max = x
  {.pop.}
  result = vector_norm(n, diffs, max, found_nan)


func math_dist_impl[T](p, q: OpenarrayOrNimIter[T]): float =
  when not openarray_Check(p):
    let p = toSeq(p)
  when not openarray_Check(q):
    let q = toSeq(q)
  math_dist_impl(p, q, dist_checkedSameLen(p, q))

func dist*[T; I: static[int]](p, q: array[I, T]): float{.raises: [].} =
  math_dist_impl(p, q, I)

func dist*[A, B](p, q: (A, B)): float{.raises: [].} =
  math_dist_impl(
    [p[0].toFloat, p[1].toFloat],
    [q[0].toFloat, q[1].toFloat],
    2)

func dist*[A, B, C](p, q: (A, B, C)): float{.raises: [].} =
  math_dist_impl(
    [p[0].toFloat, p[1].toFloat, p[2].toFloat],
    [q[0].toFloat, q[1].toFloat, q[2].toFloat],
    3)
