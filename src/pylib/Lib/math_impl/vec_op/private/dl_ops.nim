
from ../../patch/fma import c_fma, UNRELIABLE_FMA

type
  DoubleLength* = object
    hi*: float
    lo*: float

when not UNRELIABLE_FMA:
  proc dl_mul*(x: float; y: float): DoubleLength =
    ##  Algorithm 3.5. Error-free transformation of a product
    let z = x * y
    let zz = c_fma(x, y, -z)
    return DoubleLength(hi: z , lo: zz)
else:
  proc dl_split(x: float): DoubleLength =
    ##
    ##    The default implementation of dl_mul() depends on the C math library
    ##    having an accurate fma() function as required by § 7.12.13.1 of the
    ##    C99 standard.
    ##
    ##    The UNRELIABLE_FMA option is provided as a slower but accurate
    ##    alternative for builds where the fma() function is found wanting.
    ##    The speed penalty may be modest (17% slower on an Apple M1 Max),
    ##    so don't hesitate to enable this build option.
    ##
    ##    The algorithms are from the T. J. Dekker paper:
    ##    A Floating-Point Technique for Extending the Available Precision
    ##    https://csclub.uwaterloo.ca/~pbarfuss/dekker1971.pdf
    ##
    ##  Dekker (5.5) and (5.6).
    let t = x * 134217729.0
    ##  Veltkamp constant = 2.0 ** 27 + 1
    let
      hi = t - (t - x)
      lo = x - hi
    result = DoubleLength(hi: hi, lo: lo)

  proc dl_mul*(x: float; y: float): DoubleLength =
    ##  Dekker (5.12) and mul12()
    let xx = dl_split(x)
    let yy = dl_split(y)
    let
      p = xx.hi * yy.hi
      q = xx.hi * yy.lo + xx.lo * yy.hi
      z = p + q
      zz = p - z + q + xx.lo * yy.lo
    result = DoubleLength(hi: z, lo: zz)


func dl_sum*(a, b: float): DoubleLength =
  ## Algorithm 3.1 Error-free transformation of the sum
  let x = a + b
  let z = x - a
  let y = (a - (x - z)) + (b - z)
  DoubleLength(hi: x, lo: y);
