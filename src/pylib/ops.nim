import math


when not defined SomeFloat:
  ## Type class matching all floating point number types.
  ## Workaround for Error: undeclared identifier: 'SomeFloat'.
  ## SomeFloat used to be SomeReal, see:
  ## https://github.com/nim-lang/Nim/commit/efae3668570b51fa14483663d1979a6a8a6852fe
  type SomeFloat* = float | float32 | float64


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

template `/`*(x, y: BiggestInt): float = system.`/`(int(x), int(y))

proc `//`*[A, B: SomeFloat | SomeInteger](a: A, b: B): int | float =
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

proc `%`*[T: SomeNumber](a, b: T): T =
  ## Python-like modulo
  result = a - b * (a // b)

template `%`*[A: SomeFloat, B: SomeInteger](a: A, b: B): A = a % A(b)
template `%`*[A: SomeInteger; B: SomeFloat](a: A, b: B): B = B(a) % b
