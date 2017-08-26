import strutils, macros

proc printImpl*(objects: openarray[string], sep=" ", endl="\n", 
                file=stdout, flush=false) = 
  ## Print procedure implementation. Use print macro instead!
  # Write all objects joined by sep
  file.write(objects.join(sep))
  # Write end of line
  file.write(endl)
  # If flush is needed, flush the file
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
      # Add object and stringify it automatically
      objects.add(newCall("$", arg))
  # XXX: Do we need to convert objects to sequence?
  # objects = prefix(objects, "@")
  result = quote do:
    printImpl(`objects`, `arguments`)
