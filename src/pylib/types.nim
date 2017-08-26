import strutils
template str*(a: untyped): string = $a
template int*(a: string): BiggestInt = parseBiggestInt(a)
template int*[T: SomeNumber](a: T): untyped = system.int(a)
template float*(a: string): BiggestFloat = parseFloat(a)
template float*[T: SomeNumber](a: T): untyped = system.float(a)

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
