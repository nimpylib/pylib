import std/math
export math.round, math.pow  # pow for float

import ./modPow
export modPow.pow

func pow*(base, exp, modulo: float): int{.error: 
  "TypeError: pow() 3rd argument not allowed unless all arguments are integers".}
  ## raises Error like Python does, but a static error instead of runtime

func pow*(base: int, exp: Natural): int =
  ## .. warning:: `pow` with a negative `exp` shall results in float,
  ##  but for static-type lang it's not possible for a function to return
  ##  either a float or int, except for using a boxing type.
  ## Therefore for `pow(base, exp)`, `exp` cannot be negative.
  
  base ^ exp

# Power templates for different types of arguments
template `**`*[T](a: T, b: Natural): T = a ^ b
template `**`*[T: SomeFloat](a, b: T): T = pow(a, b)
template `**`*[A: SomeFloat, B: SomeInteger](a: A, b: B): A = pow(a, b)
template `**`*[A: SomeInteger; B: SomeFloat](a: A, b: B): B = pow(B(a), b)

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

type
  ArithmeticError* = object of CatchableError
  ZeroDivisionError* = object of ArithmeticError

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


func `//`*[A, B: SomeFloat | SomeInteger](a: A, b: B): SomeNumber {.inline.} =
  ## Python-like floor division
  runnableExamples:
    assert 13 // -3 == -5
    assert 13 div -3 == -4
  when A is SomeInteger and B is SomeInteger:
    (a - a % b) div b
  else:
    (a.float - a % b) / b.float

func divmod*[T: SomeNumber](x, y: T): (T, T) = 
  ## differs from std/math divmod
  (x//y, x%y)

template `==`*(a, b: typedesc): bool =
  ## Compare 2 typedesc like Python.
  runnableExamples: doAssert type(1) == type(2)
  a is b


template id*(x): int =
  runnableExamples:
    let a = 1.0
    var b = 1
    assert id(a) != id(b)
    # not the same as Python's (Python's small int is stored in pool)
    block:
      var a,b = 1
      assert id(a) != id(b)
  cast[int](
    when NimMajor > 1: x.addr
    else: x.unsafeAddr
  )

import std/macros

macro wrapop(op: static[string], obj, class_or_tuple): bool =
  if class_or_tuple.kind == nnkTupleConstr:
    template iOr(a,b): untyped = infix(a,"or",b)
    result = infix(obj, op, class_or_tuple[0])
    for i in 1..<class_or_tuple.len:
      let kid = class_or_tuple[i]
      result = iOr(result, infix(obj, op, kid))
  else:
    result = infix(obj, op, class_or_tuple)

template isinstance*(obj, class_or_tuple): bool =
  runnableExamples:
    assert isinstance(1, int)
    assert isinstance(1.0, (int, float))
    assert not isinstance('c', bool)
  wrapop "is", obj, class_or_tuple
template issubclass*(obj, class_or_tuple): bool =
  wrapop "of", obj, class_or_tuple
  
  