## builtins.complex and its operators.

import std/complex as ncomplex except im

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

func `$`*(z: PyComplex): string =
  let
    real = z.real
    imag = z.imag
  result.add '('
  if real != 0:
    result.add $real
    if imag >= 0:
      result.add '+'
    # if negative, `-` will be prefix-ed by `$`
  result.add $imag & 'j'
  result.add ')'

template pycomplex*[T](z: ncomplex.Complex[T]): PyComplex[T] =
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
func conjugate*[T](z: PyComplex[T]): PyComplex[T] = pycomplex conjugate(z.toNimComplex)

template borrowBin(op) =
  ## borrow binary op
  template op*(a, b: PyComplex): PyComplex =
    bind op
    pycomplex(op(a.toNimComplex, b.toNimComplex))

borrowBin `+`
borrowBin `-`
borrowBin `*`
borrowBin `/`
borrowBin `+=`
borrowBin `-=`
borrowBin `*=`
borrowBin `/=`
borrowBin `==`

  

