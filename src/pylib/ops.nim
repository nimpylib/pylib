import std/math

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

template `/`*(x, y: BiggestInt): float = system.`/`(int(x), int(y))

func `//`*[A, B: SomeFloat | SomeInteger](a: A, b: B): int | float {.inline.} =
  ## Python-like floor division
  let data = floor(float(a) / float(b))
  # Both arguments are float - result if float
  when A is SomeFloat and B is SomeFloat: result = data
  # Convert result to float
  elif A is SomeFloat: result = A(data)
  # Convert result to float
  elif B is SomeFloat: result = B(data)
  # Both arguments are int - result is int
  else: result = int(data)

template `%`*[T: SomeNumber](a, b: T): T =
  ## Python-like modulo
  a - b * (a // b)

template `%`*[A: SomeFloat, B: SomeInteger](a: A, b: B): A = a % A(b)
template `%`*[A: SomeInteger; B: SomeFloat](a: A, b: B): B = B(a) % b

template `==`*(a, b: typedesc): bool =
  ## Compare 2 typedesc like Python.
  runnableExamples: doAssert type(1) == type(2)
  a is b

template degress*(x: SomeFloat): untyped =
  ## https://devdocs.io/python/library/math#math.degrees
  radToDeg(x)

template radians*(x: SomeFloat): untyped =
  ## https://devdocs.io/python/library/math#math.radians
  degToRad(x)
