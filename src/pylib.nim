import strutils, math, sequtils, macros, unicode, tables
export math, tables, strutils
import pylib/pyclass
export pyclass

type 
  Iterable[T] = concept x
    for value in x:
      value is T

const
  True* = true
  False* = false

template `*`*(a: string | char, b: int): string = a.repeat(b)
template str*(a: untyped): string = $a
template int*(a: string): BiggestInt = parseBiggestInt(a)
template int*[T: SomeNumber](a: T): untyped = system.int(a)
template float*(a: string): BiggestFloat = parseFloat(a)
template float*[T: SomeNumber](a: T): untyped = system.float(a)
template `**`*[T](a: T, b: Natural): T = a ^ b
template `**`*[T: SomeReal](a, b: T): T = pow(a, b)
template `**`*[A: SomeReal, B: SomeInteger](a: A, b: B): A = pow(a, b) 
template `**`*[A: SomeInteger; B: SomeReal](a: A, b: B): B = pow(B(a), b)
template `<=`*[A: SomeInteger, B: SomeReal](a: A, b: B): bool = B(a) < b

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

converter bool*[T](arg: T): bool = 
  ## Converts argument to boolean
  ## checking python-like truthiness
  # If we have len proc for this object
  when compiles(arg.len):
    arg.len > 0
  # If we can compare if it's not 0
  elif compiles(arg != 0):
    arg != 0
  # If we can compare if it's greater than 0
  elif compiles(arg > 0):
    arg > 0 or arg < 0
  # Initialized variables only
  else:
    not arg.isNil()

proc `%`*[T: SomeNumber](a, b: T): T = a mod b

proc printImpl*(objects: openarray[string], sep = " ", endl = "\n", 
                file=stdout, flush=false) = 
  ## Print procedure implementation. Use print macro instead!
  file.write(objects.join(sep))
  file.write(endl)
  if flush:
    file.flushFile()

macro print*(data: varargs[untyped]): untyped =
  ## Print macro, which is identical to Python "print()" function with 
  ## one change: end argument renamed to endl
  var objects = newTree(nnkBracket)
  var arguments = newTree(nnkArglist)
  for arg in data:
    if arg.kind == nnkExprEqExpr:
      # Add keyword argument
      arguments.add(arg)
    else:
      # Stringify automatically
      objects.add(newCall("$", arg))
  # XXX: Do we need to convert objects to sequence?
  # objects = prefix(objects, "@")
  result = quote do:
    printImpl(`objects`, `arguments`)

proc input*(prompt = ""): string = 
  ## Python-like input procedure
  if prompt.len > 0:
    stdout.write(prompt)
  stdin.readLine()

iterator range*[T](start, stop: T, step: int, dummy = false): T = 
  ## Python-like range iterator
  ## Supports negative values!
  # dummy is used to distinguish iterators from templates, so
  # templates wouldn't end in an endless recursion
  if step == 0:
    raise newException(ValueError, "Step must not be zero!")
  if step > 0 and stop > 0:
    for x in countup(start, stop - 1, step):
      yield x
  elif step < 0:
    for x in countdown(start, stop + 1, -step):
      yield x

iterator range*[T](start, stop: T, dummy = false): T =
  for x in start..<stop: 
    yield x

iterator range*[T](stop: T, dummy = false): T = 
  for x in T(0)..<stop:
    yield x


# Templates for range so you don't need to use toSeq manually
template range*[T](start, stop: T, step: int): seq[T] = toSeq(range(start, stop, step, true))
template range*[T](start, stop: T): seq[T] = toSeq(range(start, stop, true))
template range*[T](stop: T): seq[T] = toSeq(range(stop, true))

proc all*[T](iter: Iterable[T]): bool = 
  ## Checks if all values in iterable are truthy
  result = true
  for element in iter:
    if not bool(element):
      return false

proc any*[T](iter: Iterable[T]): bool = 
  ## Checks if at least one value in iterable is truthy
  result = false
  for element in iter:
    if bool(element):
      return true

when isMainModule:
  import unittest
  suite "Python functions in Nim":
    test "Range-like Nim procedure":
      checkpoint "One argument - stop"
      check range(0).len == 0
      check range(5) == @[0, 1, 2, 3, 4]
      checkpoint "Two arguments - start and stop"
      check range(3, 5) == @[3, 4]
      checkpoint "Negative start and positive stop"
      check range(-7, 3) == @[-7, -6, -5, -4, -3, -2, -1, 0, 1, 2]
      checkpoint "3 positive arguments"
      check range(1, 10, 3) == @[1, 4, 7]
      checkpoint "Positive start, negative stop and step"
      check range(0, -10, -2) == @[0, -2, -4, -6, -8]
      check range(5, -5, -3) == @[5, 2, -1, -4]
      checkpoint "Variables"
      let a = 10
      let b = 100
      let c = 50
      check range(a, a+2) == @[a, a + 1]
      checkpoint "Errors"
      expect ValueError:
        let data = range(1, 2, 0)
    
    test "Floor division":
      check(5.0 // 2 == 2.0)
      check(5 // 2 == 2)
      check(5 // 7 == 0)
      check(-10 // 3 == -4)
      check(5 // -6 == -1)
      check(5 // -2 == -3)
      check(5 // -3 == -2)
      check(5 // -3.0 == -2.0)