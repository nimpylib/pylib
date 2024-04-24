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

func complex*[T](re, im: T): PyComplex[T] = pycomplex ncomplex.complex(re, im)
template pycomplex*[T](re, im: T): PyComplex[T] =
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

  

