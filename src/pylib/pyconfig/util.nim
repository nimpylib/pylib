

import std/os

const debug{.booldefine.} = false

const weirdTarget = defined(js) or defined(nimscript)

const cacheDir = currentSourcePath()/../".cfgcache"
when not weirdTarget:
  static:
    createDir cacheDir # noop if cacheDir dirExists
template cfgCache(fn): string = cacheDir/fn

template decl_ac_implAux(handle; subcmd; variable; defval; code) =
  when weirdTarget:
    handle variable, defval
  else:
    const fp = cfgCache astToStr variable
    when fileExists fp: handle variable, fp.slurp
    else:
      const
        res = gorgeEx( "nim " & subcmd & " --hints:" & $debug & " --eval:" & quoteShell(astToStr code) )
        resCodeS = $res.exitCode
      fp.writeFile resCodeS
      handle variable, resCodeS

template decl_global(variable; val: bool) =
  const variable* = val
template decl_global(variable; val: string) = decl_global variable, val == "1"

template decl_ac_impl(subcmd; variable; defval; code) =
  decl_ac_implAux decl_global, subcmd, variable, defval, code
const RunSubCmd = 'r'

template AC_LINK_IFELSE*(variable, defval, code) = decl_ac_impl('c', variable, defval, code)
template AC_RUN_IFELSE*(variable, defval, code) = decl_ac_impl(RunSubCmd, variable, defval, code)


template AX_C_FLOAT_WORDS_BIGENDIAN*(id; doIfTrue, doIfFalse, doIfUnknown) =
  template handle_option_bool(_; val: string){.genSym.} =
    const v = val
    when v == "1": doIfTrue
    elif v == "0": doIfFalse
    else: doIfUnknown

  decl_ac_implAux handle_option_bool, RunSubCmd, id, false:
    proc floatPatAsStr: cstring =
      {.emit: [
        "static double m[] = {9.090423496703681e+223, 0.0};\n",
        result, " = (char*)m;\n"
      #"  <- for code lint
      ].}
    let staticPtr = floatPatAsStr()
    quit:
      case staticPtr
      of "noonsees": 1  # bigEndian
      of "seesnoon": 0  # littleEndian
      else: 2


template def(sym) = {.define(sym).}

template AX_C_FLOAT_WORDS_BIGENDIAN_def*(defIfTrue, defIfFalse, doIfUnknown) =
  bind def
  template ifDo{.genSym.} = def defIfTrue
  template elseDo{.genSym.} = def defIfFalse
  AX_C_FLOAT_WORDS_BIGENDIAN(defIfTrue, ifDo, elseDo, doIfUnknown)

template c_defined*(variable; c_macro: string; headers: openArray = []) =
  const Pre{.used.} =  # NIM-BUG: must be marked by used pragma
    static:
      var pre = "/*INCLUDESECTION*/\n"
      pre.add "#include <stdlib.h>\n"
      for h in headers:
        pre.add "#include "
        pre.add h
        pre.add "\n"
      pre
  AC_RUN_IFELSE variable, false:
    {.emit: Pre.}
    proc main{.noReturn.} = {.emit:
      """
    exit(
  #if defined(""" & c_macro & """)
      1
  #else
      0
  #endif
    );
  """.}
    main()
