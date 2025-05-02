## why this module doesn't use `pow` in std/complex (we call it `ncomplex.pow` below):
## 
## - For integer 2nd arg, we'll use `c_powi`_ or `c_powu`,
##  which produce more precious result than ncomplex.pow
## - ncomplex.pow doesn't raise any exception
from std/complex as ncomplex import Complex
from std/math import copysign, hypot, pow, arctan2, exp, ln, cos, sin, floor
template atan2(x, y): untyped = arctan2(x, y)
from ../../Lib/math_impl/isX import isnan, isinf, isfinite
from ../../Lib/math_impl/errnoUtils import prepareRWErrno, setErrno, setErrno0, isErr, isErr0,
  ERANGE, EDOM
from ./pycore_pymath import Py_ADJUST_ERANGE2
from ../../pyerrors/aritherr import ZeroDivisionError

template opt_ARM64_patch(s) =
  ##  Avoid bad optimization on Windows ARM64 until the compiler is fixed
  when not defined(js) and not defined(nimscript):
    {.emit: "\n#ifdef _M_ARM64\n#pragma optimize(\"\", " & s &
      ")\n#endif\n".}
template push_ARM64_patch = opt_ARM64_patch "off"
template pop_ARM64_patch = opt_ARM64_patch "on"

proc Py_c_quot[T](a, b: Complex[T]): Complex[T] =
  ## as ncomplex.`/` is just almost the same as "the original algorithm" describled below,
  ## so we do not use it here.
  ## The following is CPython's comment:
  ##
  ## ****************************************************************
  ##     This was the original algorithm.  It's grossly prone to spurious
  ##     overflow and underflow errors.  It also merrily divides by 0 despite
  ##     checking for that(!).  The code still serves a doc purpose here, as
  ##     the algorithm following is a simple by-cases transformation of this
  ##     one:
  ##
  ##     Py_complex r;
  ##     double d = b.re*b.re + b.im*b.im;
  ##     if (d == 0.)
  ##         errno = EDOM;
  ##     r.re = (a.re*b.re + a.im*b.im)/d;
  ##     r.im = (a.im*b.re - a.re*b.im)/d;
  ##     return r;
  ## ****************************************************************
  ##  This algorithm is better, and is pretty obvious:  first divide the
  ##  numerators and denominator by whichever of {b.re, b.im} has
  ##  larger magnitude.  The earliest reference I found was to CACM
  ##  Algorithm 116 (Complex Division, Robert L. Smith, Stanford
  ##  University).
  push_ARM64_patch
  prepareRWErrno

  let abs_breal = if b.re < 0: -b.re else: b.re
  let abs_bimag = if b.im < 0: -b.im else: b.im
  if abs_breal >= abs_bimag:
    ##  divide tops and bottom by b.re
    if abs_breal == 0:
      setErrno EDOM
      result.re = 0
      result.im = 0
    else:
      let ratio = b.im / b.re
      let denom = b.re + b.im * ratio
      result.re = (a.re + a.im * ratio) / denom
      result.im = (a.im - a.re * ratio) / denom
  elif abs_bimag >= abs_breal:
    ##  divide tops and bottom by b.im
    let ratio = b.re / b.im
    let denom = b.re * ratio + b.im
    assert(b.im != 0)
    result.re = (a.re * ratio + a.im) / denom
    result.im = (a.im * ratio - a.re) / denom
  else:
    ##  At least one of b.re or b.im is a NaN
    result.re = NaN
    result.im = NaN
  ##  Recover infinities and zeros that computed as nan+nanj.  See e.g.
  ##        the C11, Annex G.5.2, routine _Cdivd().
  if isnan(result.re) and isnan(result.im):
    if (isinf(a.re) or isinf(a.im)) and isfinite(b.re) and isfinite(b.im):
      let x = copysign(if isinf(a.re): 1.0 else: 0.0, a.re)
      let y = copysign(if isinf(a.im): 1.0 else: 0.0, a.im)
      result.re = Inf * (x * b.re + y * b.im)
      result.im = Inf * (y * b.re - x * b.im)
    elif (isinf(abs_breal) or isinf(abs_bimag)) and isfinite(a.re) and
        isfinite(a.im):
      let x = copysign(if isinf(b.re): 1.0 else: 0.0, b.re)
      let y = copysign(if isinf(b.im): 1.0 else: 0.0, b.im)
      result.re = 0.0 * (a.re * x + a.im * y)
      result.im = 0.0 * (a.im * x - a.re * y)
  pop_ARM64_patch

proc Py_c_pow[T](a, b: Complex[T]): Complex[T] =
  ## `std/complex`.pow does never set errno
  prepareRWErrno
  if b.re == 0.0 and b.im == 0.0:
    result.re = 1.0
    result.im = 0.0
  elif a.re == 0.0 and a.im == 0.0:
    if b.im != 0.0 or b.re < 0.0:
      setErrno EDOM
    result.re = 0.0
    result.im = 0.0
  else:
    let
      vabs = hypot(a.re, a.im)
      at = atan2(a.im, a.re)
    var
      len = pow(vabs, b.re)
      phase = at * b.re
    if b.im != 0.0:
      len = len / exp(at * b.im)
      phase += b.im * ln(vabs)
    result.re = len * cos(phase)
    result.im = len * sin(phase)
    Py_ADJUST_ERANGE2(result.re, result.im)

template c_prod(a: var Complex, b) =
  ## inplace complex product
  ncomplex.`*=`(a, b)

template c_1[T]: Complex[T] = ncomplex.complex[T](1, 0)

func c_powuImpl[T](x: Complex[T]; n: SomeInteger): Complex[T] =
  # assuming n > 0
  var
    p = x
    mask = typeof(n) 1
  result = c_1[T]()

  # multiply in step of binary system
  while 0 < mask and mask <= n:
    # mask 1..n  in power of 2
    if bool(n and mask):
      result.c_prod p
    mask = mask shl 1
    p.c_prod p

func c_powu*[T](x: Complex[T]; n: Natural): Complex[T]{.raises:[], inline.} = c_powuImpl(x, n)

func c_powi*[T](x: Complex[T], i: SomeInteger): Complex[T]{.raises:[], inline.} =
  if i > 0: c_powuImpl(x, i)
  else: Py_c_quot(c_1[T](), c_powuImpl(x, -i))

template Py_c_pow(a, b): Complex = ncomplex.pow(a, b)

template checkedPowBody(powImplBody) =
    prepareRWErrno
    setErrno0
    powImplBody
    if isErr EDOM:
        raise newException(ZeroDivisionError,
                        "zero to a negative or complex power");

    elif isErr ERANGE:
        raise newException(OverflowDefect,
                        "complex exponentiation");

func pow*[T](a, b: Complex[T]): Complex[T] =
  checkedPowBody:
    # Check whether the exponent has a small integer value, and if so use
    # a faster and more accurate algorithm.
    if b.im == 0.0 and b.re == floor(b.re) and  # b.re still may be infinite till here
          abs(b.re) <= 100.0:
        # b.re is a finite float of [-100, 100]
        result = c_powi(a, int(b.re))
        Py_ADJUST_ERANGE2(result.re, result.im)
    else:
        result = Py_c_pow(a, b)

func pow*[T](self: Complex[T], i: SomeInteger): Complex[T] =
  checkedPowBody:
    result = c_powi(self, i)
    Py_ADJUST_ERANGE2(result.re, result.im)

func pow*[T](self: Complex[T], n: static Natural): Complex[T]{.compileTime.} =
  checkedPowBody:
    result = c_powu(self, n)
    Py_ADJUST_ERANGE2(result.re, result.im)

func powu*[T](self: Complex[T], n: Natural): Complex[T] =
  checkedPowBody:
    result = c_powu(self, n)
    Py_ADJUST_ERANGE2(result.re, result.im)
