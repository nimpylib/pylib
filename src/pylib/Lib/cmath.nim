## Lib/cmath
## 
## complex math library for [Python's complex](../builtins/complex.html) 

import ../builtins/complex

import std/complex as ncomplex except complex
from std/math import ln
from ./n_math import
  isinf, isfinite, isclose,
  pi, e, tau, inf, nan,
  py_math_isclose_impl
export pi, e, tau, inf, nan

const nanj*: PyComplex = complex(0.0, nan)
const infj*: PyComplex = complex(0.0, inf)


template expCC(sym){.dirty.} =
  template sym*(z: PyTComplex): PyTComplex =
    bind toNimComplex, pycomplex, sym
    sym(z.toNimComplex).pycomplex


func rect*[T](r, phi: T): PyTComplex[T] =
  ncomplex.rect(r, phi).toNimComplex

expCC phase
expCC polar
expCC exp
expCC log10
expCC sqrt
expCC sin


func isclose*(a,b: Complex, rel_tol=1e-09, abs_tol=0.0): bool =
  py_math_isclose_impl(abs=abs)

func log*[T](z: PyTComplex[T]): PyTComplex[T] = ln(z)  ## ln(z)
func log*[T](z: PyTComplex[T], base: SomeNumber|PyTComplex[T]): PyTComplex[T] = (ln(z) / ln(base)).pycomplex

template expAs(sym, alias){.dirty.} =
  template alias*(x: PyTComplex): untyped =
    bind pycomplex
    sym(x).pycomplex

expAs arccos, acos
expAs arcsin, asin
expAs arctan, atan
expAs arccosh, acosh
expAs arcsinh, asinh
expAs arctanh, atanh

template both(fn){.dirty.} =
  func fn*(z: PyTComplex): bool = z.re.fn and z.im.fn

both isfinite
both isnan
