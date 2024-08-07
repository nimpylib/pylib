import std/macros
import  ../Lib/sys
import ../noneType

import std/locks

var lockPrint: Lock
when nimvm: discard
else:
  lockPrint.initLock()

from std/strutils import join

when defined(js):
  import std/[jsconsole]

proc printImpl(objects: openArray[string], sep:char|string=" ", endl:char|string="\n",
              file: NoneType|File|typeof(sys.stdout) = None, flush=false) =
  template notImpl(backend) =
    raise newException(OSError, "print with file != None is not supported" &
      " for " & astToStr(backend) & " backend")
  when sep is char:
    let sep = $sep  # strutils.join only accept string sep
  when nimvm:
    const fileStd = file is NoneType
    let noEnd = objects.join(sep)
    if endl=="\n" and fileStd:
      echo noEnd
      return
    else:
      notImpl NimScript
  else:
    when defined(js):
      template toStdout =
        console.log(objects.join(sep).cstring, endl)
      when file is NoneType: toStdout
      elif file is File:
        if file == stdout: toStdout
        else: notImpl JavaScript
      else:
        if file == sys.dunder_stdout:
          toStdout
        else: notImpl JavaScript
    else:
      when file is NoneType:
        let file = sys.stdout
      # Write all objects joined by sep
      let le = len objects
      withLock lockPrint:
        if le != 0:
          file.write(objects[0])
          for i in 1..<le:
            file.write(sep)
            file.write(objects[i])
        # Write end of line
        file.write(endl)
        # If flush is needed, flush the file
        if flush:
          when file is File: file.flushFile
          else: file.flush()

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
      objects.add(newCall("$", newCall("str", arg)))
  result = quote do:
    `printProc`(`objects`, `arguments`)
