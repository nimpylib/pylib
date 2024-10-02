
import std/math
from ./pyerrors/aritherr import ZeroDivisionError


# Power templates for different types of arguments
template `**`*[T](a: T, b: Natural): T =
  runnableExamples:
    var i = -1
    doAssertRaises RangeDefect:
      discard (5 ** i)
      ## this runs iff `i` is of static[int]
      ## e.g. `5 ** -1`
  bind `^`
  a ^ b

template `**`*[T: SomeNumber](a: T; b: static[int]): int|float =
  runnableExamples:
    const f = 5 ** -1  # only when the rhs is static[int]
    assert f == 0.2
    const i = 5 ** 2
    assert i == int(25)
  when b < 0:
    bind pow
    pow(a.float, b.float)  # returns float
  else:
    bind `^`
    a ^ b  # returns int or floatd

template `**`*[T: SomeFloat](a, b: T): T = bind pow; pow(a, b)
template `**`*[A: SomeFloat, B: SomeInteger](a: A, b: B): A = bind pow; pow(a, A(b))
template `**`*[A: SomeInteger; B: SomeFloat](a: A, b: B): B = bind pow; pow(B(a), b)

template `**=`*(a: var SomeNumber, b: SomeNumber) = a = a**b

# Currently `shr` is also `arithm shr`, but it used to be `logic shr`
template `>>`*[I: SomeInteger](a, b: I): I = ashr a, b
template `<<`*[I: SomeInteger](a, b: I): I = a shl b

template `>>=`*[I: SomeInteger](a, b: I) = a = a shr b
template `<<=`*[I: SomeInteger](a, b: I) = a = a shl b

# Comparasion operators. We only need 3 of them :<, <=, ==.
# Other comparasion operators are just shortcuts to these
template `<`*[A: SomeInteger, B: SomeFloat](a: A, b: B): bool = B(a) < b
template `<`*[A: SomeFloat, B: SomeInteger](a: A, b: B): bool = a < A(b)

template `<=`*[A: SomeInteger, B: SomeFloat](a: A, b: B): bool = B(a) <= b
template `<=`*[A: SomeFloat, B: SomeInteger](a: A, b: B): bool = a <= A(b)

template `==`*[A: SomeInteger, B: SomeFloat](a: A, b: B): bool = B(a) == b
template `==`*[A: SomeFloat, B: SomeInteger](a: A, b: B): bool = a == A(b)

template `<>`*[A: SomeInteger, B: SomeFloat](a: A, b: B): bool = B(a) != b # Python 1.x and 2.x
template `<>`*[A: SomeFloat, B: SomeInteger](a: A, b: B): bool = a != A(b) # Python 1.x and 2.x

template `/`*(x: SomeInteger, y: SomeInteger): float = system.`/`(float(x), float(y))

# Nim is static-typed, but `/=` will cause lhs convert from int to float
# template `/=`*(x: var SomeInteger, y: SomeInteger)  


template zeRaise(x) =
  if x == typeof(x)(0):
    raise newException(ZeroDivisionError, "division or modulo by zero")

func `%`*[T: SomeNumber](a, b: T): T =
  ## Python-like modulo
  runnableExamples:
    assert 13 % -3 == -2
    assert -13 % 3 == 2
  zeRaise b
  # Nim's `mod` is the same as `a - b * (a // b)` (i.e. remainder), while Py's is not.
  floorMod a,b

template `%`*[A: SomeFloat, B: SomeInteger](a: A, b: B): A = a % A(b)
template `%`*[A: SomeInteger; B: SomeFloat](a: A, b: B): B = B(a) % b

template `%=`*(self: var SomeNumber, x: SomeNumber) = self = self % x

func `//`*[A, B: SomeFloat | SomeInteger](a: A, b: B): SomeNumber {.inline.} =
  ## Python-like floor division
  runnableExamples:
    assert 13 // -3 == -5
    assert 13 div -3 == -4
  when A is SomeInteger and B is SomeInteger:
    (a - a % b) div b
  else:
    (a.float - a % b) / b.float

template `//=`*[A, B: SomeFloat | SomeInteger](a: var A, b: B)=
  a = a//b

func divmod*[T: SomeNumber](x, y: T): (T, T) = 
  ## differs from std/math divmod
  (x//y, x%y)

template `==`*(a, b: typedesc): bool =
  ## Compare 2 typedesc like Python.
  runnableExamples: doAssert type(1) == type(2)
  a is b
