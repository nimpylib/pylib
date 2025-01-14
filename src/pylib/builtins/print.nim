import std/macros
import  ../Lib/sys
import ../noneType
import ../pystring/strimpl

when defined(js):
  import std/[jsconsole, jsffi]
elif not defined(nimscript):
  import std/locks
  when NimMajor == 1:
    template addExitProc(f) = addQuitProc(f)
  else:
    import std/exitprocs

from std/strutils import join, escape

# NOTE: `echo`'s newline is `\n`
template isEchoNL(c: char): bool = c == '\n'
template isEchoNL(c: string): bool = c == "\n"

template vmPrintStdoutNoNL(msg: string) =
  when defined(windows):
    # relay on PowerShell
    let
      nmsg = msg.escape.escape("", "")
      cmd = "powershell -c \"[System.Console]::Write(" & nmsg & ")\""
  else:
    let
      nmsg = escape msg
      cmd = "echo -n " & nmsg
  when declared(exec):  # NimScript
    exec cmd
  else:
    # gorge cannot help as it just returns output
    notImpl "nimvm"

type PriArgs = openArray[string]
proc printImpl(objects: PriArgs; sep:char|string=' ', endl:char|string='\n',
              file: auto = None, flush=false) =
  template notImpl(backend; supportEnd=false) =
    const msg = "print with file != None " & 
        (when supportEnd: "" else: "or endl != '\\n'") &
        " is not supported for " &
        astToStr(backend) & " backend"
    when defined(nimscript):
      {.error: "not impl: " & msg.}
    else:
      raise newException(OSError, msg)
  template vmPrintImpl =
    when file is_not NoneType:
      notImpl "NimScript", true
    # We know sys.std* cannot be modified at compile-time
    if not endl.isEchoNL:
      vmPrintStdoutNoNL(objects.join(sep) & endl)
    else:
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
        when declared(sys.stdout):
          type Param = NoneType|File|typeof(sys.stdout)
        else:
          type Param = NoneType|File
        assert file is Param
      when defined(js):
        let toStdout =
          when defined(nodejs):
            proc processStdoutWrite(s: cstring){.importjs: "process.stdout.write(#)".}
            proc (objects: PriArgs) = processStdoutWrite(cstring(objects.join(sep) & endl))
            # XXX: FIXME: this is async on Windows
          else:
            let Deno{.importcpp.}: JsObject
            let inBorwser = Deno == jsUndefined
            if inBorwser:
              if not endl.isEchoNL:
                notImpl "JavaScript"
              proc (objects: PriArgs) = console.log("%s", cstring objects.join(sep))
            else:
              proc denoStdoutWriteSync(s: cstring){.importjs:"Deno.stdout.writeSync(#)".}
              proc (objects: PriArgs) = denoStdoutWriteSync(cstring(objects.join(sep) & endl))

        when file is NoneType:
          when compiles(sys.stdout):
            if sys.stdout.isNil:
              return
          toStdout objects
        elif file is File:
          if file == system.stdout: toStdout objects
          else: notImpl "JavaScript", true
        else:
          if file == sys.dunder_stdout:
            toStdout objects
          else: notImpl "JavaScript", true
      else:
        var lockPrint{.global.}: Lock
        when nimvm: discard
        else:
          once:
            lockPrint.initLock()
            addExitProc( proc(){.noconv.} = lockPrint.deinitLock() )
        when file is NoneType:
          let file = sys.stdout
          if file.isNil:
            return
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

template printImpl(objects: PriArgs; sep:char|string=' ', `end`:char|string='\n',
  file: untyped = None, flush=false) = printImpl(objects, sep, `end`, file, flush)

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
