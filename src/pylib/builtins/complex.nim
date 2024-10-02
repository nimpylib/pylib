## builtins.complex and its operators/methods.
## 
## Use `toNimComplex` and `pycomplex` to convert between PyComplex and Complex

runnableExamples:
  assert complex(1, 3) == complex("1.0+3.0J")

  # complex only stores floats, not int,
  # just as Python's
  assert not (type(complex(1, 2).real) is int)

import std/complex as ncomplex except im, complex
from std/math import copySign, isNaN
from ./private/ncomplex_pow import nil
from ../numTypes/floats/parsefloat import parsePyFloat
import ../numTypes/utils/stripOpenArray
from ../noneType import NoneType
import ../version
import ../nimpatch/floatdollar

type
  PyTComplex*[T] = distinct Complex[T]  ## generics version of `PyComplex`_
  PyComplex* = PyTComplex[float]

template toNimComplex*[T](z: PyTComplex[T]): Complex[T] =
  Complex[T] z

template borrowAttr(expAs, attr){.dirty.} =
  ## borrow postfix, assuming returns T,
  ## and forbid setter
  template expAs*[T](z: PyTComplex[T]): T =
    bind toNimComplex
    z.toNimComplex.attr
  template `expAs=`*[T](z: PyTComplex[T], _: T){.error:
    "AttributeError: readonly attribute".} = discard

borrowAttr imag, im
borrowAttr real, re

func cut2str[T: SomeFloat](x: T): string =
  # Nim's Complex's elements can only be of float
  result = floatdollar.`$` x
  # removesuffix('.0')
  # We know $<float> will be at least 3 chars (e.g. "0.0", "inf")
  let lm2 = result.len - 2
  if result[lm2+1] == '0' and result[lm2] == '.':
    result.setLen lm2

func repr*(z: PyTComplex): string =
  ## Returns `bj/(a+bj)`/`(a-bj)` for `complex(a, b)`
  ## 
  runnableExamples:
    assert repr(complex(0.0, 3.0)) == "3j"  # not "(0+3j)", as in Python
    assert repr(complex(-0.0, 3.0)) == "(-0+3j)" # not "3j", as in Python

    assert repr(complex(1.0, 2.0)) == "(1+2j)"  # '.0' is removed as Python's
  let
    real = z.real
    imag = z.imag
  template addImag = result.add imag.cut2str & 'j'
  if real == 0.0 and copySign(1.0, real) == 1.0: #  +0.0
    #[/* Real part is +0.0: just output the imaginary part and do not
      include parens. */]#
    addImag
    return
  result.add '('
  result.add real.cut2str
  template requirePlus(x: float): bool =
    # act as `PyOS_double_to_string` with flag of `Py_DTSF_SIGN`
    x >= 0 or x.isNaN
    # NOTE: CPython's implementation does not care the sign of NaN here,
    # unconsistent with cases in other places
    # (CPython is used to caring a lot the sign of NaN)
  if requirePlus imag:
    result.add '+'
  # if negative, `-` will be prefix-ed by `$`
  addImag
  result.add ')'

func `$`*(z: PyTComplex): string = repr z

template pycomplex*[T](z: ncomplex.Complex[T]): PyTComplex[T] =
  ## Convert Nim's Complex in std/complex to PyTComplex
  bind PyTComplex
  PyTComplex[T] z

func complex*[T: SomeFloat](real: T = 0.0, imag: T = 0.0): PyTComplex[T] =
  pycomplex ncomplex.complex(real, imag)
func complex*[T: SomeInteger](real: T = 0, imag: T = 0): PyComplex =
  pycomplex ncomplex.complex(real.BiggestFloat, imag.BiggestFloat)

type
  HasIndex = concept self
    self.index() is SomeInteger
  HasFloat = concept self
    float(self) is BiggestFloat

template complex*(real, imag: HasFloat): PyComplex =
  bind complex
  complex(float(real), float(imag))

template complex*(real, imag: HasIndex): PyComplex{.
    pysince(3,8).} =
  bind complex
  complex(obj.index().BiggestFloat, obj.index().BiggestFloat)

func complex*(s: string): PyComplex =
  const errMsgPre = "complex() arg is a malformed string, reason: "
  template malformedArg(msg: string) =
    raise newException(ValueError, errMsgPre & msg)
  if s.len == 0: malformedArg("got empty string")
  # cleanup leading and trailing whitespaces and parentheses.
  var (m, n) = s.stripAsRange
  let begParen = s[m] == '('
  let endParan = s[n] == ')'
  if begParen:
    m.inc
  if endParan:
    n.dec
  if begParen and not endParan: malformedArg("missing closing parentheses")
  if endParan and not begParen:
    malformedArg("missing beginning parentheses")
  let offset = s.toOpenArray(m, n).stripAsRange
  var cur = m + offset[0]
  n = m + offset[1]
  template leftS: untyped = (s).toOpenArray(cur, n)
  template curChar: char =
    if cur > n:
      malformedArg("expecting more chars at end")
    s[cur]

  # now whitespaces and parentheses are cleanup.
  var
    re, im: float
    nParsed: int
  template isJ(c: char): bool =
    c == 'j' or c == 'J'
  template isOp(c: char): bool =
    c == '+' or c == '-'
  template checkSuffix =
    if cur > n:
      malformedArg("expect 'j' or 'J', but got nothing at index: " & $cur)
    let suffix = s[cur]
    if not suffix.isJ:
      malformedArg("expect 'j' or 'J', but got " & suffix.repr & " at index " & $cur)
    cur.inc
  nParsed = leftS.parsePyFloat re

  if nParsed != 0:
    # all 4 forms starting with <float> land here
    cur.inc nParsed
    if cur > n:
      # <float>
      return complex(re, im)
    let infix = curChar
    if infix.isOp:
      # <float><signed-float>j | <float><sign>j
      nParsed = leftS.parsePyFloat im
      if nParsed != 0:
        # <float><signed-float>j
        cur.inc nParsed
      else:
        # <float><sign>j
        im = if infix == '+': 1.0 else: -1.0
        cur.inc
      checkSuffix
    elif curChar.isJ:
      # <float>j
      cur.inc
      swap im, re
    else:
      discard  # <float> is handled above
  else:
    # not starting with <float>; must be <sign>j or j
    let prefix = curChar
    if prefix.isOp:
      # <sign>j
      im = if prefix == '+': 1.0 else: -1.0
      cur.inc
    else:
      # j
      im = 1.0
    checkSuffix
  if cur != n+1:
    malformedArg("superfluous chars in range " & $(cur..(n+1)))
  result = complex(re, im)

template pycomplex*[T](re: T; im = T(0)): PyTComplex[T] =
  ## alias of `complex`.
  ## Useful when import both std/complex and pylib
  complex(re, im)

func abs*[T](z: PyTComplex[T]): T = abs(z.toNimComplex)  ## builtins.abs for complex

func conjugate*[T](z: PyTComplex[T]): PyTComplex[T] =
  ## complex.conjugate()
  pycomplex conjugate(z.toNimComplex)

template toNimCall(op; a, b: PyTComplex): untyped = op(a.toNimComplex, b.toNimComplex)

template borrowBin(op){.dirty.} =
  ## borrow binary op
  template op*(a, b: PyTComplex): PyTComplex =
    bind op
    pycomplex(toNimCall(op, a, b))

template borrowBinRetAs(op){.dirty.} =
  ## borrow binary op, do not care result type
  template op*(a, b: PyTComplex): untyped =
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

template genMixinOp(op){.dirty.} =
  template op*[T: SomeFloat](a: T, z: PyTComplex[T]): PyTComplex[T] =
    op(complex(a), z)
  template op*[T: SomeFloat](z: PyTComplex[T], a: T): PyTComplex[T] =
    op(complex(a), z)
    
  template op*[I: Someinteger, T](a: I, z: PyTComplex[T]): PyTComplex[T] =
    op(complex(T(a)), z)
  template op*[I: SomeInteger, T](z: PyTComplex[T], a: I): PyTComplex[T] =
    op(complex(T(a)), z)

genMixinOp `+`
genMixinOp `-`
genMixinOp `*`
genMixinOp `/`


template powImpl[T](self: PyTComplex[T], x: ncomplex.Complex[T]): PyTComplex[T] =
  bind pycomplex, toNimComplex
  pycomplex ncomplex_pow.pow(self.toNimComplex, x)

template pow*[T](self: PyTComplex[T], x: PyTComplex[T]): PyTComplex[T] =
  bind powImpl, toNimComplex
  powImpl(self, x.toNimComplex)

template pow*[T](self: PyTComplex[T], x: T): PyTComplex[T] =
  bind powImpl
  powImpl(self, ncomplex.complex(x))

template pow*[T](self: PyTComplex[T], x: static Natural): PyTComplex[T] =
  bind pycomplex, toNimComplex
  pycomplex ncomplex_pow.powu(self.toNimComplex, x)

template pow*[T](self: PyTComplex[T], x: int): PyTComplex[T] =
  bind pycomplex, toNimComplex
  pycomplex ncomplex_pow.pow(self.toNimComplex, x)

type ComplexPowSecondParamType[T] = T or PyTComplex[T] or int
template `**`*[T](self: PyTComplex[T]; x: ComplexPowSecondParamType[T]): PyTComplex[T] =
  bind pow
  pow(self, x)

const NimHasBindOverloadSymBugForComplexPow* = (NimMajor, NimMinor, NimPatch) <= (2,1,9)  # XXX: at least in range (2.0.8, 2.1.9]

when NimHasBindOverloadSymBugForComplexPow:
  template `**`*[T](self: PyTComplex[T]; x: PyComplex): PyTComplex[T] =
    bind pow
    pow(self, x)
  template `**`*[T](self: PyTComplex[T]; x: int): PyTComplex[T] =
    bind pow
    pow(self, x)

func `**=`*[T](self: var PyTComplex[T]; x: ComplexPowSecondParamType[T]) =
  bind `**`
  self = self ** x

template pow*[T](self: PyTComplex[T], x: ComplexPowSecondParamType[T], _: NoneType): PyTComplex[T] =
  bind pow
  pow(self, x)

func `'j`*(s: static string): PyComplex =
  ## 1+3'j or 1+3'J
  ## 
  ## NOTE: Nim disallows custom suffixes without `'`.
  ##  Therefore, something like `1+3j` is not not allowed.
  ## Consider using `complex` instead.
  runnableExamples:
    assert 1+3'j == 1.0+3.0'J
  var imPart: BiggestFloat
  assert s.len == s.parsePyFloat imPart
  complex(0.0, imPart)
