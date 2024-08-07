import std/macros
import  ../Lib/sys
import ../noneType
import ../pystring/strimpl

when defined(js):
  import std/[jsconsole]
elif not defined(nimscript):
  import std/locks
  when NimMajor == 1:
    template addExitProc(f) = addQuitProc(f)
  else:
    import std/exitprocs

from std/strutils import join

# NOTE: `echo`'s newline is `\n`
template isEchoNL(c: char): bool = c == '\n'
template isEchoNL(c: string): bool = c == "\n"

proc printImpl(objects: openArray[string], sep:char|string=" ", endl:char|string="\n",
              file: auto = None, flush=false) =
  template notImpl(backend) =
    raise newException(OSError, "print with file != None or endl != '\n' is not supported" &
      " for " & astToStr(backend) & " backend")
  template vmPrintImpl =
    if file is_not NoneType or not endl.isEchoNL:
      notImpl "NimScript"
    # We know sys.std* cannot be modified at compile-time
    echo objects.join sep
    return
  when sep is char:
    let sep = $sep  # strutils.join only accept string sep
  when nimvm: vmPrintImpl
  else:
    when defined(nimscript):
      vmPrintImpl
    else:
      static:
        # check here instead of using `file: xxx` in param list
        # as `File` cannot appear when nimvm
        assert file is NoneType|File|typeof(sys.stdout)
      when defined(js):
        template toStdout =
          console.log(objects.join(sep).cstring, endl)
        when file is NoneType: toStdout
        elif file is File:
          if file == stdout: toStdout
          else: notImpl "JavaScript"
        else:
          if file == sys.dunder_stdout:
            toStdout
          else: notImpl "JavaScript"
      else:
        var lockPrint{.global.}: Lock
        when nimvm: discard
        else:
          once:
            lockPrint.initLock()
            addExitProc( proc(){.noconv.} = lockPrint.deinitLock() )
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
      objects.add(newCall("$", newCall(bindSym"str", arg)))
  result = quote do:
    `printProc`(`objects`, `arguments`)
