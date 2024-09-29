## Lib/math
## 
## Wrapper around `Lib/n_math<n_math.html>`_, and raises exceptions
## when math error occurs as CPython behaves.
## 

import ../version
from ./collections/abc import Iterable
from ../builtins/list_decl import `@`, list

import ./n_math
export nan
export inf
export pi
export tau
export e

from ./math_impl/err import raiseDomainErr, raiseRangeErr
from ./math_impl/errnoUtils import setErrno0, setErrno, isErr0, EDOM, ERANGE
from ./math_impl/vec_op/niter_types import toNimIterator, ClosureIter

template checkErrno(result, exc): bool =
  not isErr0() and math_is_error(result, exc)

template checkErrnoAndRaise(result) =
  var exc: ref Exception
  if not isErr0() and math_is_error(result, exc):
    raise exc

template math_1_body(x; fun; can_overflow: bool) =
  setErrno0
  result = fun(x)
  if isnan(result) and not isnan(x):
    raiseDomainErr() # invalid arg
  if isinf(result) and isfinite(x):
    when can_overflow:
      raise newException(OverflowDefect, "math range error") # overflow
    else:
      raiseDomainErr() # singularity
  var exc: ref Exception
  if isfinite(result) and result.checkErrno exc:
    # this branch unnecessary on most platforms
    raise exc

template FUNC_math_1(funcname; fun; can_overflow: bool){.dirty.} =
  ## FUNC1 with math_1_body
  func funcname*[F: SomeFloat](x: F): F =
    math_1_body(x, can_overflow)


template FUNC_math_1a(funcname; fun){.dirty.} =
  ##[variant of math_1_body, to be used when the function being wrapped is known to
   set errno properly (that is, errno = EDOM for invalid or divide-by-zero,
   errno = ERANGE for overflow).]##
  func funcname*[F: SomeFloat](x: F): F =
    setErrno0
    result = fun(x)
    result.checkErrnoAndRaise

template FUNC_math_2(funcname; fun){.dirty.} =
  ## FUNC1 with math_1_body
  func funcname*[F: SomeFloat](x, y: F): F =
    setErrno0
    result = fun(x, y)
    if isnan(result):
      if not isnan(x) and not isnan(y):
        setErrno EDOM
      else:
        setErrno0
    elif isinf(result):
      if isfinite(x) and isfinite(y):
        setErrno ERANGE
      else:
        setErrno0
    result.checkErrnoAndRaise

template FUNC_math_1(fun; can_overflow: bool){.dirty.} =
  ## wrap n_math's
  FUNC_math_1(fun, n_math.fun, can_overflow)

template FUNC_math_1a(fun){.dirty.} =
  ## wrap n_math's
  FUNC_math_1a(fun, n_math.fun)

template FUNC_math_2(fun){.dirty.} =
  ## wrap n_math's
  FUNC_math_2(fun, n_math.fun)

template expN(sym) = export n_math.sym

template genDunder(sym) =
  # Nim cannot write dunder (double under)
  # so we just export AS-IS
  export n_math.sym

# NOTE: the following is the same with CPython's

FUNC_math_1 acos,  false
FUNC_math_1 acosh, false
FUNC_math_1 asin,  false
FUNC_math_1 asinh, false
FUNC_math_1 atan,  false
FUNC_math_1 atanh, false

func cbrt*[F: SomeFloat](x: F): F{.pysince(3,11).} =
  runnableExamples:
    template chk =
      assert cbrt(-1.0) == -1.0
    chk()
    static: chk()
  math_1_body(x, n_math.cbrt, false)  # check for underflow

genDunder ceil

FUNC_math_2 atan2

FUNC_math_2 copysign

FUNC_math_1 cos,   false
FUNC_math_1 cosh,  true

FUNC_math_1a erf
FUNC_math_1a erfc

FUNC_math_1 exp,   true

func expm1*[F: SomeFloat](x: F): F{.pysince(3,11).} =
  math_1_body(x, expm1, true)

FUNC_math_1 fabs,  false

genDunder floor

FUNC_math_1a gamma
FUNC_math_1a lgamma

FUNC_math_1 log1p, false
FUNC_math_2 remainder

FUNC_math_1 sin,  false
FUNC_math_1 sinh, true
FUNC_math_1 sqrt, false
FUNC_math_1 tan,  false
FUNC_math_1 tanh, false

expN fsum

func isqrt*[I: SomeInteger](x: I): int =
  if x < 0:
    raise newException(ValueError, "isqrt() argument must be nonnegative")
  n_math.isqrt(cast[Natural](int(x)))

func factorial*(x: int): int =
  if x < 0:
    raise newException(ValueError, "factorial() not defined for negative values")
  n_math.factorial(cast[Natural](x))

genDunder trunc

expN frexp  # XXX: CPython's math_frexp_impl does not check errno

func ldexp*(x: SomeFloat, i: int): float =
  var exc: ref Exception
  result = ldexp(x, i, exc)
  if exc.isNil: return
  raise exc

expN modf  # XXX: CPython's math_modf_impl does not check errno


func loghelper[F](arg: SomeNumber, fun: proc (x: F)): F =
  when arg is SomeInteger:
    if arg <= 0:
      raiseDomainErr()
      # XXX: CPython said following:
      #[/*Here the conversion to double overflowed, but it's possible
               to compute the log anyway.  Clear the exception and continue. */]#
      # but that's for Python's `int`, and is it impossible for C's fixed int to overflow double
    let x = float arg
    result = fun(x)
  else:
    math_1_body(arg, fun, false)


template logImpl[F](x: F): F = loghelper(x, n_math.log)

func log*[F: SomeFloat](x: F): F =
  logImpl x

func log*[F: SomeFloat](x, base: F): F =
  logImpl(x) / logImpl(base)


func log2*[F: SomeFloat](x: F): F = loghelper(x, n_math.log2)
func log10*[F: SomeFloat](x: F): F = loghelper(x, n_math.log10)

func fma*[F: SomeFloat](x, y, z: F): F =
  var exc: ref Exception
  result = n_math.fma(x, y, z, exc)
  if not exc.isNil:
    raise exc

func fmod*[F: SomeFloat](x: F, y: F): F =
    result = n_math.fmod(x, y)
    # not check `isinf(result)` here
    result.checkErrnoAndRaise


proc iterToFloatSeq[T](it: Iterable[T]): seq[float] =
  for e in it:
    result.add:
      when T is SomeFloat: e.float
      else: e.toFloat

template gen2pointsGetFloat(sym; pypatch: int; listOp; iterOp; oaOp; niterOp){.dirty.} =
  template sym*[T](p, q: list[T]): float {.pysince(3,pypatch).} =
    bind listOp
    n_math.sym(listOp p, listOp q)
  template sym*[T](p, q: Iterable[T]): float {.pysince(3,pypatch).} =
    bind iterOp
    n_math.sym(iterOp[T](p), iterOp[T](q))
  template sym*[T](p, q: openarray[T]): float {.pysince(3,pypatch).} =
    bind oaOp
    n_math.sym(oaOp(p), oaOp(q))
  template sym*[T](p, q: ClosureIter[T]): float {.pysince(3,pypatch).} =
    bind niterOp
    n_math.sym(niterOp(p), niterOp(q))

template asisOp[T](x: T): T = x

gen2pointsGetFloat dist,    8,  `@`,    iterToFloatSeq, asisOp, iterToFloatSeq

gen2pointsGetFloat sumprod ,12, toNimIterator, toNimIterator, toNimIterator, asisOp


expN hypot

func pow*[F: SomeFloat](x, y: F): F =
  result = n_math.pow(x, y)
  result.checkErrnoAndRaise

expN degrees
expN radians

expN isfinite
expN isnan
expN isinf

expN isclose  # n_math.isclose alreadly make it

expN prod

template chkValNe(x): Natural =
  if x < 0:
    raise newException(ValueError, astToStr(x) &
      " must be a non-negative integer")
  cast[Natural](x)

func perm*(n: int): int =
  let nn = chkValNe n
  n_math.factorial nn

func perm*(n, k: int): int =
  let
    nn = chkValNe n
    nk = chkValNe k
  n_math.perm(nn, nk)

func comb*(n, k: int): int =
  let
    nn = chkValNe n
    nk = chkValNe k
  n_math.comb(nn, nk)

func nextafter*[F: SomeFloat](x, y: F): F{.pysince(3,9).} = n_math.nextafter(x, y)
func nextafter*[F: SomeFloat](x, y: F; steps: int|uint64): F{.pysince(3,12).} =
  n_math.nextafter(x, y, steps)
func ulp*[F: SomeFloat](x: F): F{.pysince(3,9).} = n_math.ulp(x)

expN gcd
expN lcm

