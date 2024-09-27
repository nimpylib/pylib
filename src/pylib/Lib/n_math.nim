## 
## Nim's Python-like math,  but raises no catchable exception,
## using `errno` to report math error.
## a.k.a. non will be raised (but not for `Defect`s)
## 
## which allows fast code.
## 
## For Python-like error handler (exception-based), see `Lib/math<./math.html>`_
## 
## Also
## this is not just a module that wraps
## Nim's `std/math<https://nim-lang.org/docs/math.html>`_,
## 
## but also providing some extensions that Nim's std/math lacks, for example:
## 
## - JavaScript Backend and Compile-time (Nim VM) support for `ldexp`_, `frexp`_
## - JavaScript Backend support for `erf`_, `erfc`_, `gamma`_, `lgamma`_
## - `fsum`_, `prod`_, etc.
## 
## And fix some non-C99 behavior on some systems,
## e.g. log(-ve) -> -Inf on Solaris
## 
## *NOTE*: Currently int is not acceptable when it comes to float about functions

import std/math
import std/bitops
import std/macros
from ./math_impl/platformUtils import CLike, clikeOr
from ./math_impl/errnoUtils import
  prepareRWErrno, prepareROErrno, setErrno, setErrno0, getErrno, isErr, isErr0
from ./math_impl/ldexp import c_ldexp
from ./errno import ERANGE, EDOM

macro impPatch(sym) =
  #import ./math_impl/patch/sym
  # HINT: using `template (sym) = import ./math_impl/patch/sym`
  #  may fail on some platforms like Android (termux) and nimdoc on Ubuntu
  nnkImportStmt.newTree(
    infix(
      nnkPrefix.newTree(ident"./",
        ident"math_impl/patch"
      ),
      "/",
      sym
    )
  )


template impExpPatch(sym) =
  impPatch sym
  export sym

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

import ./math_impl/isX
export isX

template c_fmod[F: SomeFloat](x: F, y: F): F =
  ## equal to `x - x*trunc(x/y)`
  x mod y  # math.`mod`
  # nim's math.`mod` does what fmod does.
  # in C backend, it just `importc` fmod

func pow*[F: SomeFloat](x, y: F): F =
  #[/*deal directly with IEEE specials, to cope with problems on various
  platforms whose semantics don't exactly match C99 */]#
  if not isfinite(x) or not isfinite(y):
    setErrno0
    result =
      if isnan(x):
        if y == 0.0: 1.0 else: x  # NaN**0 = 1
      elif isnan(y):
        if x == 1.0: 1.0 else: y  # 1**NaN = 1
      elif isinf(x):
        let odd_y = isfinite(y) and c_fmod(abs(y), 2.0) == 1.0
        if y > 0.0:
          if odd_y: x else: abs(x)
        elif y == 0.0:
          1.0
        else:
          if odd_y: math.copySign(0.0, x) else: 0.0
      else:
        assert isinf(y)
        let abs_x = abs(x)
        if abs_x == 1.0: 1.0
        elif y > 0.0 and abs_x > 1.0: y
        elif y < 0.0 and abs_x < 1.0: -y  # result is +inf
        else: 0.0
  else:
    # let libm handle finite**finite
    setErrno0
    result = math.pow(x, y)
    #[a NaN result should arise only from (-ve)**(finite
      non-integer); in this case we want to raise ValueError.]#
    if not isfinite(result):
      if isnan(result):
        if isnan(result):
          setErrno EDOM
        #[
          an infinite result here arises either from:
          (A) (+/-0.)**negative (-> divide-by-zero)
          (B) overflow of x**y with x and y finite
        ]#
        elif isinf(result):
          if x == 0.0:
            setErrno EDOM
          else:
            setErrno ERANGE


expM copysign

template aliasFF(fn, nimfn){.dirty.} =
  func fn*[F: SomeFloat](x: F): F = nimfn(x)

aliasFF fabs, abs  # system.abs, limited for float only

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

template reduceGen(sym; Constr){.dirty.} =
  func sym*[I: Constr](x, y: I): I = math.sym(x, y)
  func sym*[I: Constr](x, y, z: I, args: varargs[I]): I =
    result = sym(x, y)
    result = sym(result, z)
    for i in args:
      result = sym(result, i)

reduceGen gcd, SomeInteger
reduceGen lcm, SomeInteger

reduceGen hypot, SomeFloat

when not defined(js):
  # Those in std/math are not available for JS
  expM erf
  expM erfc
else:
  impExpPatch erf
  export erfc

impPatch gamma
impPatch lgamma

func gamma*[F: SomeFloat](x: F): F =
  let err = x.gamma result
  case err
  of geDom, geGotNegInf: setErrno EDOM
  of geOverFlow: setErrno ERANGE
  of geUnderFlow, geZeroCantDetSign: discard
  of geOk: discard

func lgamma*[F: SomeFloat](x: F): F =
  let err = x.lgamma result
  case err
  of geOverFlow, geUnderFlow: doAssert false, "unreachable"
  of geDom: setErrno EDOM
  of geGotNegInf: discard  # math_impl/patch.lgamma alreadly returns +inf
  of geZeroCantDetSign: setErrno EDOM
  of geOk: discard

expM exp

template impJsOrC(sym, cfloatSym, argSym){.dirty.} =
  when defined(js):
    func sym(argSym: float): float{.importjs: "Math." & astToStr(sym) & "(#)".}
    func sym(argSym: float32): float32 = float32(sym(float argSym))
  elif CLike:
    {.push header: "<math.h>".}
    func sym(arg: c_double): c_double{.importc.}
    func cfloatSym(arg: c_float): c_float{.importc.}
    {.pop.}
    func sym(argSym: float): float = float sym(arg=c_double(argSym))
    func sym(argSym: float32): float32 = float32 cfloatSym c_float(argSym)
  else:
    {.error: "unreachable".}

impJsOrC expm1, expm1f, native_x
func expm1*[F: SomeFloat](x: F): F =
  expm1(native_x=x)

import ./math_impl/patch/ldexp_frexp/frexp as pure_frexp
func n_frexp(x: SomeFloat): (float, int) = pure_frexp.frexp(x.float)

func frexpImpl(x: SomeFloat): (float, int){.inline.} =
  #[ deal with special cases directly, to sidestep platform
      differences ]#
  if isnan(x) or isinf(x) or x == 0:
    return (x, 0)
  result = math.frexp(x)

func frexp*(x: SomeFloat): (float, int) =
    clikeOr(
      frexpImpl(x),
      n_frexp(x)
    )


when CLike:
  proc c_strerror(code: cint): cstring{.importc: "strerror", header: "<string.h>".}
  func errnoMsg(errnoCode: cint): string = $c_strerror(errnoCode)
elif defined(js):
  func errnoMsg(errnoCode: cint): string =
    doAssert false, "unreachable (see errnoUtils.Errno enum shall be count out)"

func math_is_error*(x: SomeFloat, exc: var ref Exception): bool{.exportc.} =
  ##[ inner usage (used by Lib/math).

  Call this when errno != 0, and where x is the result libm
returned.  This will usually set up an exception and return
true, but may return false without setting up an exception.]##
  prepareROErrno
  result = true  # presumption of guilt
  assert not isErr0()  # non-zero errno is a precondition for calling
  if isErr EDOM:
    exc = newException(ValueError, "math domain error")
  elif isErr ERANGE:
    #[ ANSI C generally requires libm functions to set ERANGE
      on overflow, but also generally *allows* them to set
      ERANGE on underflow too.  There's no consistency about
      the latter across platforms.
      Alas, C99 never requires that errno be set.
      Here we suppress the underflow errors (libm functions
      should return a zero on underflow, and +- HUGE_VAL on
      overflow, so testing the result for zero suffices to
      distinguish the cases).
      
      On some platforms (Ubuntu/ia64) it seems that errno can be
      set to ERANGE for subnormal results that do *not* underflow
      to zero.  So to be safe, we'll ignore ERANGE whenever the
      function result is less than 1.5 in absolute value.
      
      bpo-46018: Changed to 1.5 to ensure underflows in expm1()
      are correctly detected, since the function may underflow
      toward -1.0 rather than 0.0.
      ]#
    if abs(x) < 1.5:
      result = false
    else:
      exc = newException(OverflowDefect,
                        "math range error")
  else:
    # Unexpected math error
    exc = newException(ValueError, errnoMsg(getErrno()))


func ldexp*(x: SomeFloat, i: int, exc: var ref Exception): float{.raises: [].} =
  ## set exception to `exc` instead of raising it
  ## 
  ## `exc`:
  ## 
  ## - set to nil if no error
  ## - set to suitable exc if some error occurs
  # translated from CPython's `math_ldexp_impl`

  # NaNs, zeros and infinities are returned unchanged 
  prepareRWErrno
  if x == 0.0 or not isfinite(x):
    # Nim's int is not Python's `LongObject`
    # and we can leave Overflow for Nim to handle
    result = x
    setErrno0
  elif i > typeof(i)(high c_int):
    result = copySign(Inf, x)
    setErrno ERANGE
  elif i < typeof(i)(low c_int):
    # underflow to +-0
    result = copySign(0.0, x)
    setErrno0
  else:
    setErrno0
    let exp = cast[c_int](i)  # we have checked range above.
    result = 
      c_ldexp(x, exp)
    if isinf(result):
      setErrno ERANGE
  if not isErr0() and math_is_error(result, exc):
    return
  exc = nil

func ldexp*(x: SomeFloat, i: int): float{.raises: [].} =
  ## .. hint:: only set errno
  var exc_unused: ref Exception
  ldexp(x, i, exc_unused)

func modf*[F: SomeFloat](x: F): tuple[intpart: F, floatpart: F] =
  #[ Though C99 specifies it:
  /*some platforms don't do the right thing for NaNs and
  infinities, so we take care of special cases directly. */]#
  if isinf(x): return (math.copySign(0.0, x), x)
  if isnan(x): return (x, x)
  setErrno0
  result = splitDecimal x

func fmod*[F: SomeFloat](x: F, y: F): F =
  # fmod(x, +/-Inf) returns x for finite x.
  if isinf(y) and isfinite(x):
    return x
  setErrno0
  result = c_fmod(x, y)
  if isnan(result):
    if isnan(result):
      if not isnan(x) and not isnan(y):
        setErrno EDOM
      else:
        setErrno0

func remainder*[F: SomeFloat](x: F, y: F): F =
  #[ the simplest but not exact impl:
  let
    fx = y.float
    fy = x.float
  fx - fy * round(fx/fy)
  ]#
  # Deal with most common case first.
  if isfinite(x) and isfinite(y):
    if y == 0:
      return NaN
    let
      absx = abs(x)
      absy = abs(y)
      m = c_fmod(absx, absy)
    #[        /*
    Warning: some subtlety here. What we *want* to know at this point is
    whether the remainder m is less than, equal to, or greater than half
    of absy. However, we can't do that comparison directly because we
    can't be sure that 0.5*absy is representable (the multiplication
    might incur precision loss due to underflow). So instead we compare
    m with the complement c = absy - m: m < 0.5*absy if and only if m <
    c, and so on. The catch is that absy - m might also not be
    representable, but it turns out that it doesn't matter:

    - if m > 0.5*absy then absy - m is exactly representable, by
      Sterbenz's lemma, so m > c
    - if m == 0.5*absy then again absy - m is exactly representable
      and m == c
    - if m < 0.5*absy then either (i) 0.5*absy is exactly representable,
      in which case 0.5*absy < absy - m, so 0.5*absy <= c and hence m <
      c, or (ii) absy is tiny, either subnormal or in the lowest normal
      binade. Then absy - m is exactly representable and again m < c.
        */]#
    let c = absy - m
    if m < c:
      result = m
    elif m > c:
      result = -c
    else:
      #[/*
      Here absx is exactly halfway between two multiples of absy,
      and we need to choose the even multiple. x now has the form

          absx = n * absy + m

      for some integer n (recalling that m = 0.5*absy at this point).
      If n is even we want to return m; if n is odd, we need to
      return -m.

      So

          0.5 * (absx - m) = (n/2) * absy

      and now reducing modulo absy gives us:

                                        | m, if n is odd
          fmod(0.5 * (absx - m), absy) = |
                                        | 0, if n is even

      Now m - 2.0 * fmod(...) gives the desired result: m
      if n is even, -m if m is odd.

      Note that all steps in fmod(0.5 * (absx - m), absy)
      will be computed exactly, with no rounding error
      introduced.*/]#
      assert m == c
      result = m - 2.0 * c_fmod(0.5 * (absx - m), absy)
    return math.copySign(1.0, x) * result
  
  # Special values.
  if isnan(x): return x
  if isnan(y): return y
  if isinf(x): return NaN
  assert isinf(y)
  result = x

type
  # same as pylib.nim's
  Iterable[T] = concept x
    for value in x:
      value is T


func prod*[T](iterable: Iterable[T], start=1.T): T =
  result = start
  for i in iterable:
    result *= i


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
        # XXX: Python raises MemeryError on lack of memory;
        # But in Nim, by default OutOfMemDefect won't be raised unless
        # system.outOfMemHook is accordingly set.
        # But we set it here is not suitable as we don't know how to reset it.
        p.setLen m
        #except OutOfMemDefect:
        #  raise newException(MemoryError, "math.fsum partials")
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


template genLog(fun, nimFunc){.dirty.} =
  ##[
  /*Various platforms (Solaris, OpenBSD) do nonstandard things for log(0),
log(-ve), log(NaN).  Here are wrappers for log and log10 that deal with
special values directly, passing positive non-special values through to
the system log/log10.*/
  And, as I tested on Solaris 11.4, using `Sun C 5.13 SunOS_i386 2014/10/20`:

  log(-ve) -> -Inf,
  and errno is set to ERANGE (instead of EDOM)!
  ]##
  func fun*[F: SomeFloat](x: F): F =
    if isfinite(x):
      if x > 0.0:
        return math.nimFunc(x)
      setErrno EDOM
      if x == 0.0:
          return NegInf  # log(0) = -inf
      else:
          return NaN  # log(-ve) = nan
    elif isnan(x):
      return x  # log(nan) = nan
    elif x > 0.0:
      return x  # log(inf) = inf
    else:
      setErrno EDOM
      return NaN # log(-inf) = nan

genLog log, ln
func log*[F: SomeFloat](x, base: F): F =
  let
    num = log(x)
    den = log(base)
  result = num / den


genLog log2, log2
genLog log10, log10

impJsOrC log1p, log1pf, x_native

func log1p*[F: SomeFloat](x: F): F =
  #[ from CPython/Modules/_math.h _Py_log1p:
  /*Some platforms (e.g. MacOS X 10.8, see gh-59682) supply a log1p function
but don't respect the sign of zero:  log1p(-0.0) gives 0.0 instead of
the correct result of -0.0.

To save fiddling with configure tests and platform checks, we handle the
special case of zero input directly on all platforms.*/]#
  if x == 0.0: x  # respect its sign
  else: log1p(x_native=x)

aliasFF degrees, radToDeg

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


func comb*(n, k: int): int =
  ## .. hint:: Python's math.comb does not accept negative value for n, k
  ##   but Nim's std/math.binom allows, so this function allows too.
  ##   For consistent behavior with Python, see `Lib/math.comb<./math.html#comb>`_
  binom(n, k)

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

func isqrtPositive*(n: Positive): int{.inline.} =
  ## EXT: isqrt for Positive only,
  ## as we all know, in Python:
  ##    - isqrt(0) == 0
  ##    - isqrt(-int)
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

func isqrt*(n: Natural): int{.raises: [].} =
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
  if n == 0: 0
  else: isqrtPositive(n)


func isqrt*[T: SomeFloat](x: T): int{.raises: [].} =
  ## .. hint:: assuming x > 0 (raise `RangeDefect` otherwise (if not danger build))
  ## use math.isqrt if expecting raising `ValueError`
  let i = Natural(x)
  isqrt i

when CLike:
  {.push header: "<math.h>".}
  proc c_fma(x, y, z: cdouble): cdouble{.importc: "fma".}
  proc c_fma(x, y, z: cfloat): cfloat{.importc: "fmaf".}
  {.pop.}
  func fma*[F: SomeFloat](x, y, z: F, exc: var ref Exception): F{.raises: [].} =
    ## EXT.
    result = c_fma(x, y, z)

    # Fast path: if we got a finite result, we're done.
    if isfinite(result):
      return result
    template all3(f): bool =
      f(x) and f(y) and f(z)
    template notNaN(x): bool = not isnan(x)

    # Non-finite result. Raise an exception if appropriate, else return r.
    if isnan(result):
      if all3 notNaN:
        # NaN result from non-NaN inputs.
        exc = newException(ValueError, "invalid operation in fma")
        return
    elif all3 isfinite:
      exc = newException(OverflowDefect, "overflow in fma")
      return
  func fma*[F: SomeFloat](x, y, z: F): F{.raises: [].} =
    ## .. warning:: this fma does not touch errno and exception is discarded
    var exc_unused: ref Exception
    fma(x, y, z, exc_unused)

else:
  func fma*[F: SomeFloat](x: F): F{.error: "not impl for weird target".}

