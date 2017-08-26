import strutils, math, sequtils, macros, unicode, tables
export math, tables, strutils
import pylib/class
export class

type 
  Iterable*[T] = concept x
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