## builtins.complex and its operators/methods.
## 
## Use `toNimComplex` and `pycomplex` to convert between PyComplex and Complex

runnableExamples:
  assert complex(1, 3) == complex("1.0+3.0J")
  assert complex(1, 3) == 1 + 3.J

  # complex only stores floats, not int,
  # just as Python's
  assert not (type(complex(1, 2).real) is int)

import std/complex as ncomplex except im, complex, pow
export ncomplex.`/`  # XXX: NIM-BUG: or 
#[ lib/pure/complex.nim's `func inv*[T](z: Complex[T])` will:
Error: type mismatch
Expression: conjugate(z) / abs2(z)
  [1] conjugate(z): Complex[system.float64]
  [2] abs2(z): float64]#
from std/math import copySign, isNaN
import ./private/ncomplex_pow
from ../numTypes/floats/parsefloat import parsePyFloat
import ../numTypes/utils/stripOpenArray
from ../noneType import NoneType
import ../version
import ../nimpatch/floatdollar

type
  PyTComplex*[T] = distinct Complex[T]  ## generics version of `PyComplex`_
  PyComplex* = PyTComplex[float]

template toNimComplex*[T](z: PyTComplex[T]): Complex[T] = Complex[T] z

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

template toPyComplex[T](z: ncomplex.Complex[T]): PyTComplex[T] =
  ## Convert Nim's Complex in std/complex to PyTComplex
  bind PyTComplex
  PyTComplex[T] z
template pycomplex*[T](z: ncomplex.Complex[T]): PyTComplex[T] =
  bind toPyComplex
  toPyComplex z

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
  complex(real.index().BiggestFloat, imag.index().BiggestFloat)

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

template pycomplex(z: SomeInteger): PyComplex = pycomplex(float(z))

func abs*[T](z: PyTComplex[T]): T = abs(z.toNimComplex)  ## builtins.abs for complex

func conjugate*[T](z: PyTComplex[T]): PyTComplex[T] =
  ## complex.conjugate()
  pycomplex conjugate(z.toNimComplex)

template AsIs[T](x: T): T = x

template toNimCallArg[T](x: PyTComplex[T]): ncomplex.Complex[T] = x.toNimComplex
template toNimCallArg[F: SomeFloat](x: F): ncomplex.Complex[F] = ncomplex.complex(x)
template toNimCallArg[F: SomeFloat](x: SomeInteger): ncomplex.Complex[F] = toNimCallArg(F x)

template toNimCall[T](op; a, b): untyped =
  bind toNimComplex
  op(a.toNimCallArg[:T], b.toNimCallArg[:T])

template genBinOpT(name, op, TA, TB: untyped, retMap: typed){.dirty.} =
  ## borrow binary op, do not care result type
  template name*[T](a: TA, b: TB): untyped =
    bind op, toNimCall, retMap
    retMap toNimCall[T](op, a, b)

template borrowBin(name; op; transSelf=true, retMap: typed=AsIs, arg2Int=true) =
  genBinOpT name, op, PyTComplex[T], PyTComplex[T], retMap
  when not defined(pylibNoLenient):
    genBinOpT name, op, PyTComplex[T], T, retMap
    when arg2Int:
      genBinOpT name, op, PyTComplex[T], SomeInteger, retMap
    when transSelf:
      genBinOpT name, op, T, PyTComplex[T], retMap
      genBinOpT name, op, SomeInteger, PyTComplex[T], retMap

template borrowBinIop(op) = borrowBin(op, op, transSelf=false)
template borrowBinRet(name; op; arg2I=true) =
  borrowBin(name, op, transSelf=true, retMap=toPyComplex, arg2Int=arg2I)

template borrowBinRet(op; arg2I=true) = borrowBinRet(op, op, arg2I)

borrowBinRet `+`
borrowBinRet `-`
borrowBinRet `*`
borrowBinRet `/`
borrowBinRet pow, arg2I=false
borrowBinRet `**`, op=pow, arg2I=false
borrowBin `==`, `==`
borrowBinIop `+=`
borrowBinIop `-=`
borrowBinIop `*=`
borrowBinIop `/=`

template genPow(name){.dirty.} =
  template name*[T](self: PyTComplex[T], x: static Natural): PyTComplex[T] =
    bind pycomplex, toNimComplex
    pycomplex ncomplex_pow.powu(self.toNimComplex, x)

  template name*[T](self: PyTComplex[T], x: SomeInteger): PyTComplex[T] =
    bind pycomplex, toNimComplex
    pycomplex ncomplex_pow.pow(self.toNimComplex, x)

genPow pow
genPow `**`

type ComplexPowSecondParamType[T] = T or PyTComplex[T]

func `**=`*[T](self: var PyTComplex[T]; x: ComplexPowSecondParamType[T]|SomeInteger) =
  bind `**`
  self = self ** x

template genPow3(TA, TB){.dirty} =
  template pow*[T](self: TA, x: TB, _: NoneType): PyTComplex[T] =
    bind pow
    pow(self, x)

genPow3 PyTComplex[T], ComplexPowSecondParamType[T]|SomeInteger
genPow3 ComplexPowSecondParamType[T]|SomeInteger, PyTComplex[T]

func `'j`*(s: static string): PyComplex =
  ## 1+3'j or 1+3'J
  ## 
  ## .. note:: Nim disallows custom suffixes without `'`.
  ##  Therefore, something like `1+3j` is not not allowed.
  ## 
  ## Consider using `complex` or `j`_ instead,
  ## which are totaly Python syntax compatiable.
  runnableExamples:
    assert 1+3'j == 1.0+3.0'J
  var imPart: BiggestFloat
  assert s.len == s.parsePyFloat imPart
  complex(0.0, imPart)

template j*(i: int{lit}): PyComplex =
  runnableExamples:
    assert complex(1, 3) == 1+3.j
  bind complex
  complex(0.0, float(i))

template J*(i: int{lit}): PyComplex =
  ## the same as `j`_, e.g. `1+3.J`
  bind complex
  complex(0.0, float(i))
