import math

# Power templates for different types of arguments
template `**`*[T](a: T, b: Natural): T = a ^ b
template `**`*[T: SomeReal](a, b: T): T = pow(a, b)
template `**`*[A: SomeReal, B: SomeInteger](a: A, b: B): A = pow(a, b) 
template `**`*[A: SomeInteger; B: SomeReal](a: A, b: B): B = pow(B(a), b)

# Comparasion operators. We only need 3 of them:
# <, <=, ==, since others comparasion operators are just shortcuts to these
template `<`*[A: SomeInteger, B: SomeReal](a: A, b: B): bool = B(a) < b
template `<`*[A: SomeReal, B: SomeInteger](a: A, b: B): bool = a < A(b)

template `<=`*[A: SomeInteger, B: SomeReal](a: A, b: B): bool = B(a) <= b
template `<=`*[A: SomeReal, B: SomeInteger](a: A, b: B): bool = a <= A(b)

template `==`*[A: SomeInteger, B: SomeReal](a: A, b: B): bool = B(a) == b
template `==`*[A: SomeReal, B: SomeInteger](a: A, b: B): bool = a == A(b)

# Modulo python-like shortcut
template `%`*[T: SomeNumber](a, b: T): T = a mod b
template `%`*[A: SomeReal, B: SomeInteger](a: A, b: B): A = a mod A(b)
template `%`*[A: SomeInteger; B: SomeReal](a: A, b: B): B = B(a) mod b

template `/`*(x, y: BiggestInt): float = system.`/`(int(x), int(y))

proc `//`*[A, B: SomeReal | SomeInteger](a: A, b: B): int | float {.inline.} = 
  ## Python-like floor division
  let data = floor(float(a) / float(b))
  # Both arguments are float - result if float
  when A is SomeReal and B is SomeReal: result = data
  # Convert result to float
  elif A is SomeReal: result = A(data)
  # Convert result to float
  elif B is SomeReal: result = B(data)
  # Both arguments are int - result is int
  else: result = int(data)