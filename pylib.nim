import strutils, math, sequtils, strfmt, macros, unicode, tables
export strfmt, math, tables, strutils
type 
  Iterable[T] = concept x
    for value in x:
      type(value) is T

const
  True* = true
  False* = false

template `*`*(a: string | char, b: int): string = a.repeat(b)
template str*(a: untyped): string = $a
template int*(a: string): BiggestInt = parseBiggestInt(a)
template float*(a: string): BiggestFloat = parseFloat(a)

converter bool*[T](arg: T): bool = 
  # If we have len proc for this object
  when compiles(arg.len):
    arg.len > 0
  # If we can compare if it's not 0
  elif compiles(arg != 0):
    arg != 0
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
  if prompt.len > 0:
    stdout.write(prompt)
  stdin.readLine()

iterator range*[T](start, stop: T, step: int): T = 
  ## Range iterator similar to python's "range"
  ## Supports negative values!
  if step > 0 and stop > 0:
    for x in countup(start, stop - 1, step):
      yield x
  elif step < 0:
    for x in countdown(start, stop + 1, -step):
      yield x

iterator range*[T](start, stop: T): T = 
  for x in range(start, stop, 1): 
    yield x

iterator range*[T](stop: T): T = 
  for x in range(T(0), stop, 1):
    yield x

template range*[T](start, stop: T): seq[T] = toSeq(range(start, stop, step = 1))
template range*[T](stop: T): seq[T] = toSeq(range(0, stop, step = 1))

proc all[T](iter: Iterable[T]): bool = 
  for element in iter:
    if not bool(element):
      return False
  return True

proc any[T](iter: Iterable[T]): bool = 
  for element in iter:
    if element:
      return True
  return False