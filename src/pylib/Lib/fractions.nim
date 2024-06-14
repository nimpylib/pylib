
import std/rationals
import std/math
import std/strutils

type
  FractionInt* = int
  TFraction*[T] = ref object
    data: Rational[T]
  PyFraction* = TFraction[FractionInt]

func newPyFraction*: PyFraction = new result
func toTFraction*[T](r: Rational[T]): PyFraction =
  result = newPyFraction()
  result.data = r
func toPyFraction*(r: Rational[int]): PyFraction =
  toTFraction r

template wrapBinary(sym, tosym; Res){.dirty.} =
  func sym*(a, b: PyFraction): Res =
    tosym(a.data, b.data)

template wrapBinary(sym, tosym){.dirty.} =
  func sym*(a, b: PyFraction): PyFraction =
    toPyFraction tosym(a.data, b.data)
  func sym*(a: PyFraction, b: int): PyFraction =
    toPyFraction tosym(a.data, toRational b)
  func sym*(b: int, a: PyFraction): PyFraction =
    toPyFraction tosym(a.data, toRational b)
  func sym*(a: PyFraction, b: float): float =
    tosym(a.data.toFloat, b)
  func sym*(b: float, a: PyFraction): float =
    tosym(a.data.toFloat, b)


template wrapBinary(sym) = wrapBinary sym, sym

template wrapBinaryNoRet(sym, tosym){.dirty.} =
  func sym*(a, b: PyFraction) =
    tosym(a.data, b.data)
  func sym*(a: PyFraction, b: int) =
    tosym(a.data, toRational b)
  func sym*(a: PyFraction, b: float){.error:
    "Python allowed this but make `self` to a float".}
template wrapBinaryNoRet(sym) = wrapBinaryNoRet sym, sym

using self: PyFraction

func numerator*(self): FractionInt =
  self.data.num
func denominator*(self): FractionInt =
  self.data.den

func is_integer*(self): bool = self.data.den == 1

template cannotSet(a){.dirty.} =
  func `a=`*(self; v: FractionInt){.error: "AttributeError: can't set attribute".}

cannotSet numerator
cannotSet denominator

func hash*(self): int = self.data.hash.int

func Fraction*(other: PyFraction): PyFraction =
  result = toPyFraction other.data

func Fraction*(f: float): PyFraction = toPyFraction toRational f
func from_float*(typ: typedesc[PyFraction], flt: float): PyFraction =
  Fraction flt

func Fraction*(numerator = 0, denominator = 1): PyFraction =
  toPyFraction initRational(num=numerator, den=denominator)

func parseIntFraction*(res: var Rational[int], str: string): bool =
  let nstr = str.strip()
  let idx = str.find '/'
  if idx == -1: return false
  res.num = parseInt nstr[0..<idx]
  res.den = parseInt nstr[(idx+1)..^1]
  res.reduce()
  result = true

func Fraction*(str: string): PyFraction =
  var ra: Rational[int]
  if ra.parseIntFraction str:
    toPyFraction ra
  elif '.' notin str:
    Fraction str.strip().parseInt
  else:
    Fraction str.parseFloat

wrapBinary `//`, floorDiv, FractionInt

wrapBinary `+`
wrapBinary `-`
wrapBinary `*`
wrapBinary `/`
wrapBinary `%`, floorMod

wrapBinaryNoRet `+=`
wrapBinaryNoRet `-=`
wrapBinaryNoRet `*=`
wrapBinaryNoRet `/=`
func `%=`*(self; other: PyFraction) =
  self.data = floorMod(self.data, other.data)

template wrapPred(sym) =
  wrapBinary sym, sym, bool
wrapPred `<`
wrapPred `<=`
wrapPred `==`

func repr*(self): string =
  "Fraction(" & $self.numerator & '/' & $self.denominator & ')'

func `$`*(self): string =
  if self.denominator == 1:
    return $self.numerator
  $self.numerator & '/' & $self.denominator

func round*(self): int =
  self.data.toInt

func round*(self; ndigits: int): float =
  self.data.toFloat.round ndigits

func float*(self): system.float =
  self.data.toFloat

func floor*(self): int =
  self.data.toFloat.floor.int
func ceil*(self): int =
  self.data.toFloat.ceil.int

func as_integer_ratio*(self): (FractionInt, FractionInt) =
  (self.numerator, self.denominator)

template conjugate*(self): PyFraction = self
template real*(self): PyFraction = self
template imag*(self): int = 0

func abs*(self): PyFraction =
  self.data.abs.toPyFraction
