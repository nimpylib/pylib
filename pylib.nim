import strutils, math, sequtils, strfmt, macros
export strfmt
const
  True* = true
  False* = false

converter toBool*[T](arg: T): bool = 
  # If we have len proc for this object
  when compiles(arg.len):
    arg.len > 0
  # If we have `>` proc
  elif compiles(arg > 0):
    arg > 0
  # Check if it's not nil
  else:
    not arg.isNil()

proc printImpl*(objects: openarray[string], sep = " ", endl = "\n", 
                file=stdout, flush=false) = 
  ## Print procedure implementation. Use print macro instead!
  file.write(objects.join(sep))
  file.write(endl)
  if flush:
    file.flushFile()

macro print*(data: varargs[untyped]): untyped =
  ## Print macro, which is identical to Python "print()" function with 
  ##one change: end argument renamed to endl
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

proc input*(prompt: string): string = 
  stdin.readLine()

template `*`*(a: string | char, b: int): string = 
  a.repeat(b)

template str*(a: untyped): string = $a
template int*(a: string): BiggestInt = parseBiggestInt(a)
template float*(a: string): BiggestFloat = parseFloat(a)
template bool*(a: untyped) = a.toBool()
template `%`*[A, B: SomeNumber](a: A, b: B): typed = a mod b

iterator range[T](start, stop: T, step: int): T = 
  if step > 0 and stop > 0:
    for x in countup(start, stop - 1, step):
      yield x
  elif step < 0:
    for x in countdown(start, stop + 1, -step):
      yield x

iterator range[T](start, stop: T): T = 
  for x in range(start, stop, 1): 
    yield x

iterator range[T](stop: T): T = 
  for x in range(0, stop, 1):
    yield x

template range*[T](start, stop: T): seq[T] = toSeq(range(start, stop, step = 1))
template range*[T](stop: T): seq[T] = toSeq(range(0, stop, step = 1))