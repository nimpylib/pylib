
import std/os
when defined(js):
  import ../../jsutils/denoAttrs

const
  hasArgn = declared(paramCount)
  hasArgs = declared(paramStr)

when defined(js):
  when defined(nodejs):
    let execPath{.importjs: "process.execPath".}: cstring
  else:
    func getExecPath: cstring =
      # Deno.execPath() may ask permission,
      #  so we only invoke it when called
      {.noSideEffect.}:
        if inDeno:
          asm "`result` = Deno.execPath()"
        else: result = ""


template genArgs*(St, Ls; S; lsCopy, lsOfCap){.dirty.} =
  bind hasArgn, hasArgs,
    paramCount, paramStr

  when hasArgn and hasArgs:
    ## under shared lib in POSIX, paramStr and paramCount are not available

    let
      argn = paramCount()
      argc = argn + 1
    var
      orig_argv* = lsOfCap[St](argc)  ##\
        ## .. hint:: rely on
        ##    `paramCount`<https://nim-lang.org/docs/cmdline.html#paramCount>_ and
        ##    `paramStr`<https://nim-lang.org/docs/cmdline.html#paramStr%2Cint>_.
        ##    See their document for availability.
      argv*: Ls[St]

    for i in 0..argn:
      orig_argv.append S paramStr i
    when defined(nimscript):
      if argn > 0:
        argv =
          if orig_argv[1] == "e":
            orig_argv[2..^1]
          else:
            assert orig_argv[1][^5..^1] == ".nims" or
              orig_argv[1].startsWith "-"  # [--opt...] --eval:cmd
            orig_argv[1..^1]
    else: argv = lsCopy(orig_argv)

  when defined(nimscript):
    template executable*: St = S getCurrentCompilerExe()
  elif defined(js):
    template executable*: St =
      let execPath{.importByNodeOrDeno("process?.execPath", "execPath()")}: cstring
      S $execPath
  else:
    template executable*: St =
      ## returns:
      ##
      ##   - when nimscript, path of `Nim`;
      ##   - when JavaScript:
      ##     - on browser: empty string
      ##     - on NodeJS/Deno: executable path of Node/Deno
      ##   - otherwise, it's the path of current app/exe.
      S getAppFilename()
