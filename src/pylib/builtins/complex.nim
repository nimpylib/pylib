## builtins.complex and its operators/methods.
## 
## Use `toNimComplex` and `pycomplex` to convert between PyComplex and Complex

runnableExamples:
  assert complex(1, 3) == 1.0+3.0'J

  # complex only stores floats, not int,
  # just as Python's
  assert not (type(complex(1, 2).real) is int)

import std/complex as ncomplex except im, complex
from std/strutils import parseFloat

type PyComplex*[T] = distinct Complex[T]

template toNimComplex*[T](z: PyComplex[T]): Complex[T] =
  Complex[T] z

template borrowAttr(expAs, attr) =
  ## borrow postfix, assuming returns T
  template expAs*[T](z: PyComplex[T]): T =
    bind toNimComplex
    z.toNimComplex.attr

borrowAttr imag, im
borrowAttr real, re

func cut2str[T: SomeFloat](x: T): string =
  # Nim's Complex's elements can only be of float
  result = $x
  # removesuffix('.0')
  # We know $<float> will be at least 3 chars (e.g. "0.0")
  let lm2 = result.len - 2
  if result[lm2+1] == '0' and result[lm2] == '.':
    result.setLen lm2

func `$`*(z: PyComplex): string =
  ## Returns `(a+bj)`/`(a-bj)` for `complex(a, b)`
  ## 
  runnableExamples:
    assert $complex(1.0, 2.0) == "(1+2j)"  # '.0' is removed as Python's
  let
    real = z.real
    imag = z.imag
  result.add '('
  if real != 0:
    result.add real.cut2str
    if imag >= 0:
      result.add '+'
    # if negative, `-` will be prefix-ed by `$`
  result.add imag.cut2str & 'j'
  result.add ')'

template pycomplex*[T](z: ncomplex.Complex[T]): PyComplex[T] =
  ## Convert Nim's Complex in std/complex to PyComplex
  bind PyComplex
  PyComplex[T] z

func complex*[T: SomeFloat](re: T = 0.0, im: T = 0.0): PyComplex[T] =
  pycomplex ncomplex.complex(re, im)
func complex*[T: SomeInteger](re: T = 0, im: T = 0): PyComplex[BiggestFloat] =
  pycomplex ncomplex.complex(re.BiggestFloat, im.BiggestFloat)

template pycomplex*[T](re: T; im = T(0)): PyComplex[T] =
  ## alias of `complex`.
  ## Useful when import both std/complex and pylib
  complex(re, im)

func abs*[T](z: PyComplex[T]): T = abs(z.toNimComplex)  ## builtins.abs for complex

func conjugate*[T](z: PyComplex[T]): PyComplex[T] =
  ## complex.conjugate()
  pycomplex conjugate(z.toNimComplex)

template toNimCall(op; a, b: PyComplex): untyped = op(a.toNimComplex, b.toNimComplex)

template borrowBin(op) =
  ## borrow binary op
  template op*(a, b: PyComplex): PyComplex =
    bind op
    pycomplex(toNimCall(op, a, b))

template borrowBinRetAs(op) =
  ## borrow binary op, do not care result type
  template op*(a, b: PyComplex): untyped =
    bind op
    toNimCall(op, a, b)

borrowBin `+`
borrowBin `-`
borrowBin `*`
borrowBin `/`
borrowBinRetAs `+=`
borrowBinRetAs `-=`
borrowBinRetAs `*=`
borrowBinRetAs `/=`
borrowBinRetAs `==`

template genMixinOp(op) =
  template op*[T: SomeFloat](a: T, z: PyComplex[T]): PyComplex[T] =
    op(complex(a), z)
  template op*[T: SomeFloat](z: PyComplex[T], a: T): PyComplex[T] =
    op(complex(a), z)
    
  template op*[I: Someinteger, T](a: I, z: PyComplex[T]): PyComplex[T] =
    op(complex(T(a)), z)
  template op*[I: SomeInteger, T](z: PyComplex[T], a: I): PyComplex[T] =
    op(complex(T(a)), z)

genMixinOp `+`
genMixinOp `-`
genMixinOp `*`
genMixinOp `/`

template `'j`*(lit: string): PyComplex =
  ## 1+3'j or 1+3'J
  ## 
  ## NOTE: Nim disallows custom suffixes without `'`.
  ##  Therefore, something like `1+3j` is not not allowed.
  ## Consider using `complex` instead.
  runnableExamples:
    assert 1+3'j == 1.0+3.0'J

  complex(0.0, lit.parseFloat)
