import strutils, macros

proc printImpl(objects: openarray[string], sep=" ", endl="\n",
                file=stdout, flush=false) =
  # Write all objects joined by sep
  file.write(objects.join(sep))
  # Write end of line
  file.write(endl)
  # If flush is needed, flush the file
  if flush:
    file.flushFile()

macro print*(data: varargs[untyped]): untyped =
  ## Print macro identical to Python "print()" function with
  ## one change: end argument was renamed to endl
  let printProc = bindSym("printImpl")
  var objects = newTree(nnkBracket)
  var arguments = newTree(nnkArglist)
  for arg in data:
    if arg.kind == nnkExprEqExpr:
      # Add keyword argument
      arguments.add(arg)
    else:
      # Add object and stringify it automatically
      objects.add(newCall("$", arg))
  result = quote do:
    `printProc`(`objects`, `arguments`)
