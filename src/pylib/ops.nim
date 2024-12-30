
import std/math
from ./pyerrors/aritherr import ZeroDivisionError

## ## why no `/=`?
## For `template `/=`*(x: var SomeInteger, y: SomeInteger)`:
## 
## Nim is static-typed, but `/=` will cause lhs convert from int to float


# Power templates for different types of arguments
template `**`*[T](a: T, b: Natural): T =
  ## power for `b` is a non-static integer:
  ## 
  ## only Natural is acceptable unless `b` is static,
  ## see `\`**\`(a: T; b: static[int])`_
  runnableExamples:
    var i = -1
    doAssertRaises RangeDefect:
      discard (5 ** i)
      ## this runs iff `i` is of static[int]
      ## e.g. `5 ** -1`
  bind `^`
  a ^ b

template `**`*[T: SomeInteger](a: T; b: static[int]): int|float =
  ## power for static int `b`
  ## 
  ## so that result type can be inferred:
  ## 
  ## - int if `b >= 0`
  ## - float if `b < 0`
  ## 
  ## For non-static int `b`, `\`**\`(a: T; b: Natural)`_ is used.
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
    a ^ b  # returns int

template `**`*[T: SomeFloat](a, b: T): T =
  bind pow
  pow(a, b)
template `**`*[A: SomeFloat, B: SomeInteger](a: A, b: B): A =
  bind pow
  pow(a, A(b))
template `**`*[A: SomeInteger; B: SomeFloat](a: A, b: B): B =
  bind pow
  pow(B(a), b)

template `**=`*(a: var SomeNumber, b: SomeNumber) =
  bind `**`
  a = a**b

# Currently `shr` is also `arithm shr`, but it used to be `logic shr`
template `>>`*[I: SomeInteger](a, b: I): I = ashr a, b
template `<<`*[I: SomeInteger](a, b: I): I =
  ## .. warning:: this causes overflow silently.
  ##  Yet Python's int never overflows.
  a shl b

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


template zeRaise(x) =
  if x == typeof(x)(0):
    raise newException(ZeroDivisionError, "division or modulo by zero")

func `%`*[T: SomeNumber](a, b: T): T =
  ## Python's modulo (a.k.a `floor modulo`)  (`quotient`)
  ## 
  ## .. hint:: Nim's `mod` is the same as `a - b * (a div b)` (`remainder`),
  ##   just like `C`.
  runnableExamples:
    assert 13 % -3 == -2
    assert -13 % 3 == 2
  zeRaise b
  floorMod a,b

template `%`*[A: SomeFloat, B: SomeInteger](a: A, b: B): A = a % A(b)
template `%`*[A: SomeInteger; B: SomeFloat](a: A, b: B): B = B(a) % b

template `%=`*(self: var SomeNumber, x: SomeNumber) = self = self % x

func `//`*[A, B: SomeFloat | SomeInteger](a: A, b: B): SomeNumber {.inline.} =
  ## Python's division (a.k.a. `floor division`)
  ## 
  ## .. hint:: Nim's `div` is division with any fractional part discarded
  ##    (a.k.a."truncation toward zero"), just like `C`.
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
  ## differs from `std/math` `divmod`, see `//`_ and `%`_ for details.
  (x//y, x%y)

template `==`*(a, b: typedesc): bool =
  ## Compare 2 typedesc like Python.
  runnableExamples: doAssert type(1) == type(2)
  a is b
