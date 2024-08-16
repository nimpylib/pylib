## 
## *NOTE*: Currently int is not acceptable when it comes to float about functions

import std/math
import std/bitops
import std/macros

template impPatch(sym) =
  import ./math_patch/sym
  export sym

const CLike = defined(c) or defined(cpp)

template clikeOr(inCLike, b): untyped =
  # for nimvm-able expr
  when nimvm: b
  else:
    when CLike: inCLike
    else: b

template aCap(s: var string) =
  let c = s[0]
  let nc = char(uint8(c) xor 0b0010_0000'u8)
  s[0] = nc

macro expUp(x) =
  var s = x.strVal
  aCap s
  let nId = ident s
  result = quote do:
    const `x`* = `nId`

# consts:
expUp nan  # system.NaN
expUp inf  # system.Inf
expUp pi
expUp tau
expup e

template expM(x) = export math.x

#expM pow  # pylib.nim has exported it


expM copysign

template aliasFF(fn, nimfn){.dirty.} =
  func fn*[F: SomeFloat](x: F): F = nimfn(x)

aliasFF fabs, abs  # system.abs, limited for float only

expM isnan


func n_isfinite(x: SomeFloat): bool{.used.} =
  let cls = classify(x)
  result = cls != fcInf and cls != fcNegInf and cls != fcNan

func n_isinf(x: SomeFloat): bool{.used.} =
  let cls = classify(x)
  cls == fcInf or cls == fcNegInf

when defined(js):
  func js_isfiniteImpl(x: float): bool{.importjs: "Number.isFinite(#)".}
  func js_isfinite(x: SomeFloat): bool = float(x).js_isfiniteImpl
  func js_isinf(x: SomeFloat): bool =
    not x.isnan and not x.js_isfinite

template wrap(sym, c_sym, n_sym, js_sym){.dirty.} =
  func c_sym(x: c_double|c_float): c_int{.importc: astToStr(sym), header: "<math.h>".}
  func sym*(x: SomeFloat): bool =
    when nimvm: n_sym(x)
    else:
      when CLike:
        bool c_sym (when x is float32: x.c_float else: x.c_double)
      elif defined(js): js_sym x
      else: n_sym(x)

wrap isfinite, c_isfinite, n_isfinite, js_isfinite
wrap isinf, c_isinf, n_isinf, js_isinf

static:
  assert declared isinf
  assert declared isfinite

func chkIntFromFloat(x: float) =
  ## check impl of `PyLong_FromDouble`
  if x.isnan:
    raise newException(ValueError, "cannot convert float NaN to integer")
  if x.isinf:
    raise newException(OverflowDefect,
      "cannot convert float infinity to integer")

template genToInt(sym){.dirty.} =
  func sym*(x: SomeFloat): int =
    ## .. hint:: unlike C/Nim's returning float,
    ##   Python's returns `int` and raises errors for nans and infinities
    chkIntFromFloat x
    int sym x

genToInt ceil
genToInt floor
genToInt trunc

template py_math_isclose_impl*(abs) =
  ## inner use. Implementation of isclose.
  ##
  ## mixin a, b, isinf, rel_tol, abs_tol
  if rel_tol < 0.0 or abs_tol < 0.0:
    raise newException(ValueError, "tolerances must be non-negative")
  if a == b:
    return 1
  if isinf(a) or isinf(b):
    return 0
  let diff = fabs(b - a)
  result =
    diff <= fabs(rel_tol * b) or
    diff <= fabs(rel_tol * a) or
    diff <= abs_tol

func isclose*(a,b: SomeFloat, rel_tol=1e-09, abs_tol=0.0): bool =
  py_math_isclose_impl(abs=fabs)

expM gcd
expM lcm

aliasFF dist, hypot


when not defined(js):
  # Those in std/math are not available for JS
  expM erf
  expM erfc

  expM gamma
  expM lgamma
else:
  impPatch gamma

expM exp
func expm1*[F: SomeFloat](x: F): F = exp(x) - 1

expM frexp

when CLike:
  {.push header: "<math.h>".}
  proc ldexpf(arg: c_float, exp: c_int): c_float{.importc.}
  proc ldexp(arg: c_double, exp: c_int): c_double{.importc.}
  {.pop.}

func n_ldexp(x: SomeFloat, i: int): float{.used.} =
  ## a version of `ldexp`_ that's implemented in pure Nim, used by ldexp in weridTarget
  ##
  ## translated from
  ## https://blog.codefrau.net/2014/08/deconstructing-floats-frexp-and-ldexp.html
  ## which is for JS.
  ## XXX: Not sure if suitable for Obj-C
  let steps = min(3, int ceil(abs(i)/1023) )
  result = x
  for step in 0..<steps:
    result *= pow(2, floor((step+i)/steps))

template raiseDomainErr =
  raise newException(ValueError, "math domain error") 

template raiseRangeErr =
  raise newException(OverflowDefect, " math range error")

func ldexp*(x: SomeFloat, i: int): float =
  # NaNs, zeros and infinities are returned unchanged 
  if x == 0.0 or not isfinite(x):
    # Nim's int is not Python's `LongObject`
    # and we can leave Overflow for Nim to handle
    result = x
  else:
    var
      exp: c_int
      erange = false
    if i > cast[typeof(i)](high c_int):
      result = copySign(Inf, x)
      erange = true
      exp = high c_int
    elif i < cast[typeof(i)](low c_int):
      # underflow to +-0
      result = copySign(0.0, x)
      exp = low c_int
    else:
      exp = cast[c_int](i)  # we have checked range above.
      result = 
        clikeOr(
          when x is float32: ldexpf(x.c_float, exp)
          else: ldexp(x.c_double, exp),
          n_ldexp(x, i)
        )
      if result.isinf():
        erange = true
    template chk_error(x: float) =
      # a ldexp-only `is_error` of CPython
      if erange:
        if not (fabs(x) < 1.5):
          raiseRangeErr()
    chk_error(result)

func modf*(x: SomeFloat): tuple[intpart: float, floatpart: float] =
  splitDecimal x.float

func fmod*(x: SomeNumber, y: SomeNumber): float =
  ## equal to `x - x*trunc(x/y)`
  result = x.float mod y.float
  if result.isnan:
    raiseDomainErr()
# nim's math.`mod` alreadly does what fmod does.

func remainder*(x: SomeNumber, y: SomeNumber): float =
  let
    fx = y.float
    fy = x.float
  fx - fy * round(fx/fy)

type
  # same as pylib.nim's
  Iterable[T] = concept x
    for value in x:
      value is T


func prod*[T](iterable: Iterable[T], start=1.T): T =
  result = start
  for i in iterable:
    result *= i


type MemoryError* = OutOfMemDefect

const NUM_PARTIALS = 32

func fsum*[T: SomeFloat](iterable: Iterable[T]): T =

  # translated from CPython v3.10.5 `Modules/mathmodule.c`

  type Size = BiggestUint
  var n = 0.Size # len
  var m: Size = NUM_PARTIALS # cap

  var x, y: T
  var p = newSeq[T](NUM_PARTIALS)

  var xsave: T
  var special_sum, inf_sum: T = 0.0
  var hi, yr, lo{.volatile.}: T

  for orix in iterable:   # for x in iterable
    assert(0 <= n and n <= m);
    #assert((m == NUM_PARTIALS && p == ps) ||(m >  NUM_PARTIALS && p != nil));

    x = orix # as ox is immutable
    xsave = x
    var i: Size = 0
    for j in 0..<n:   # for y in partials
      y = p[j];
      if abs(x) < abs(y):
        swap x, y
      hi = x + y
      yr = hi - x
      lo = y - yr
      if lo != 0.0:
        # p.add lo
        p[i] = lo
        i.inc
      x = hi
    # now `x` is the highest (max), `xsave` is the second

    n = i # ps[i:] = [x]
    if x != 0.0:
      if not isfinite(x):
        #[ a nonfinite x could arise either as
          a result of intermediate overflow, or
          as a result of a nan or inf in the
          summands ]#
        if isfinite(xsave):
          raise newException(OverflowDefect,
                "intermediate overflow in fsum")

        if isinf(xsave):
          inf_sum += xsave
        special_sum += xsave
        # reset partials
        n = 0
      elif n >= m:
        #_fsum_realloc(&p, n, ps, &m)
        m *= 2
        try:
          p.setLen m
        except OutOfMemDefect:
          raise newException(MemoryError, "math.fsum partials")
      else:
        p[n] = x
        n.inc

  if special_sum != 0.0:
    if isnan(inf_sum):
      raise newException(ValueError,
                      "-inf + inf in fsum");
    else:
      result = special_sum
      return

  hi = 0.0
  if n > 0:
    n.dec
    hi = p[n]
    #[ sum_exact(ps, hi) from the top, stop when the sum becomes
      inexact. ]#
    while n > 0:
      x = hi
      n.dec
      y = p[n]
      assert(abs(y) < abs(x))
      hi = x + y
      yr = hi - x
      lo = y - yr
      if (lo != 0.0):
        break
    #[ Make half-even rounding work across multiple partials.
      Needed so that sum([1e-16, 1, 1e16]) will round-up the last
      digit to two instead of down to zero (the 1e-16 makes the 1
      slightly closer to two).  With a potential 1 ULP rounding
      error fixed-up, math.fsum() can guarantee commutativity. ]#
    if (n > 0 and ((lo < 0.0 and p[n-1] < 0.0) or
                  (lo > 0.0 and p[n-1] > 0.0))):
      y = lo * 2.0
      x = hi + y
      yr = x - hi
      if y == yr:
        hi = x

  result = hi

expM log
aliasFF log, ln

expM log2
expM log10

func log1p*[F: SomeFloat](x: F): F = log(1+x)

aliasFF degress, radToDeg

aliasFF radians, degToRad

expM sin
expM sinh
expM cos
expM cosh
expM tan
expM tanh


aliasFF asin, arcsin
aliasFF asinh, arcsinh
aliasFF acos, arccos
aliasFF acosh, arccosh
aliasFF atan, arctan
aliasFF atan2, arctan2
aliasFF atanh, arctanh


func comb*(n, k: int): int = binom(n, k)

func perm*(n: int): int =
  ## equal to `perm(n,n)`, returns `n!`
  fac n

func perm*(n, k: Natural): int =
  if k > n: return 0
  result = n
  for i in 1..<k:
    result *= n-i


func factorial*(x: Natural): int =
  fac x

expM sqrt

const BitPerByte = 8
func bit_length(x: SomeInteger): int =
  sizeof(x) * BitPerByte - bitops.countLeadingZeroBits x

func isqrt*[T: SomeNumber](x: T): int =
  runnableExamples:
    assert 2 == isqrt 5
  #[ the following is from CPython 3.10.5 source `Modules/mathmodule.c`:

    Here's Python code: 

    def isqrt(n):
        """
        Return the integer part of the square root of the input.
        """
        n = operator.index(n)

        if n < 0: raise ValueError("isqrt() argument must be nonnegative")
        if n == 0: return 0

        c = (n.bit_length() - 1) // 2
        a = 1
        d = 0
        for s in reversed(range(c.bit_length())):
            # Loop invariant: (a-1)**2 < (n >> 2*(c - d)) < (a+1)**2
            e = d
            d = c >> s
            a = (a << d - e - 1) + (n >> 2*c - e - d + 1) // a

        return a - (a*a > n)]#
  let n = int(x)

  if n < 0:
    raise newException(ValueError, "isqrt() argument must be nonnegative")
  if n == 0: return 0
  let c = (n.bit_length() - 1) div 2
  var
    a = 1
    d = 0
  if c != 0:
    for s in countdown(c.bit_length() - 1, 0):
      # Loop invariant: (a-1)**2 < (n >> 2*(c - d)) < (a+1)**2
      let e = d
      d = c shr s
      a = (a shl d - e - 1) + (n shr (2*c) - e - d + 1) div a

  result = a
  if (a*a > n):
    result.dec

