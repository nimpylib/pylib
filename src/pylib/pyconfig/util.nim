

import std/os
from std/strutils import parseInt, strip, multiReplace
import std/macros

const weirdTarget = defined(js) or defined(nimscript)
const pylibDebug = defined(pylibDebugPyConfig)
const cacheDir = currentSourcePath()/../".cfgcache"
when not weirdTarget:
  static:
    createDir cacheDir # noop if cacheDir dirExists
template cfgCache(fn): string = cacheDir/fn
const
  nimExePath = getCurrentCompilerExe()
  nimExeQuotedPath = when declared(quoteShell): nimExePath.quoteShell
  else: nimExePath.quoteShellWindows  # when JS
template decl_ac_implAux(handle; subcmd; variable; defval; doWithExecRes; code): untyped =
  bind nimExeQuotedPath
  when weirdTarget:
    handle variable, defval
  else:
    const fp = cfgCache astToStr variable
    when fileExists fp: handle variable, fp.slurp
    else:
      const
        scode = astToStr code
        res = gorgeEx( nimExeQuotedPath & ' ' & subcmd & " --hints:"&(when pylibDebug: "on" else: "off")&" --eval:" & quoteShell(scode) )
        resCodeS = doWithExecRes res
      when pylibDebug:
        static:echo scode
      fp.writeFile resCodeS
      handle variable, resCodeS

template decl_ac_implAux(handle; subcmd; variable; defval; code): untyped =
  template handle_exec_res(res): string{.genSym, used.} =
    when pylibDebug:
      echo res.output
    $res.exitCode
  decl_ac_implAux(handle, subcmd, variable, defval, handle_exec_res, code)


template decl_ac_implAuxGetOutput(handle; subcmd; variable; defval: int; code): untyped =
  template handle_exec_res(res): string{.genSym, used.} =
    if res.exitCode != 0: $defval
    else: res.output
  decl_ac_implAux(handle, subcmd, variable, defval, handle_exec_res, code)

template decl_global(variable; val: bool) =
  const variable* = val
template decl_global(variable; val: string) = decl_global variable, val == "0"

template decl_ac_impl(subcmd; variable; defval; code) =
  decl_ac_implAux decl_global, subcmd, variable, defval, code
const RunSubCmd = 'r'

template handle_int_or_strint(_; val: int|string): int =
  bind parseInt
  when val is int: val
  else: parseInt val

template from_c_int*(variable; defval: int; precode): int =
  bind handle_int_or_strint
  decl_ac_implAuxGetOutput(handle_int_or_strint, 'r', variable, defval):
    precode
    let variable{.importc, nodecl.}: cint
    stdout.write variable

proc from_c_int_expr(cacheName, cexpr: string; defval: NimNode): NimNode =
  let pureVarId = newLit cacheName
  result = quote do:
    from_c_int(`cexpr`, `defval`):
      {.emit: ["/*VARSECTION*/\n#define ", `pureVarId`, " ", `cexpr`, "\n"].}
#" <- for code lint
macro from_c_int_underlined*(variable: static[string]; defval: int): int =
  let pureVar = variable.strip(chars = {'_'})
  from_c_int_expr(pureVar, variable, defval)

macro from_c_int_expr*(cExpr: static[string]; defval: int): int =
  let pureVar = cExpr.multiReplace(
    ("_", ""),
    ("(", "%28"),
    (")", "%29"),
    (" ", "%20"),
    (",", "%2C"),
    ("<", "%3C"),
    (">", "%3E"),
    (":", "%3A"),
    ("\"", "%22"),
    ("/", "%2F"),
    ("\\", "%5C"),
    ("|", "%7C"),
    ("?", "%3F"),
    ("*", "%2A"),
  )
  from_c_int_expr(pureVar, cExpr, defval)

template from_c_int*(variable; includeFile: static[string], defval = low(int)): int =
  ## we know int.low is smaller than low(cint)
  bind handle_int_or_strint
  decl_ac_implAuxGetOutput(handle_int_or_strint, 'r', variable, defval):
    let variable{.importc, header: includeFile.}: cint
    stdout.write variable

template noop = discard
template from_c_int*(variable; defvar: int): int =
  bind noop
  from_c_int(variable, defvar, noop)

template AC_LINK_IFELSE*(variable, defval, code) = decl_ac_impl('c', variable, defval, code)  ## variable = whether code exits with 0
template AC_RUN_IFELSE*(variable, defval, code) = decl_ac_impl(RunSubCmd, variable, defval, code)


template AX_C_FLOAT_WORDS_BIGENDIAN*(id; doIfTrue, doIfFalse, doIfUnknown){.dirty.} =
  bind decl_ac_implAux, RunSubCmd, weirdTarget
  when weirdTarget:
    template handle_option_bool(_; val: bool){.genSym.} =
      doIfUnknown
  else:
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
      0
  #else
      1
  #endif
    );
  """.}
    main()

template AC_CHECK_FUNC*(res, function) =
  ## export const HAVE_`function`
  AC_LINK_IFELSE res, false:
    const fname{.inject.} = astToStr(function)
    {.emit: [
      "/*INCLUDESECTION*/\n",
      "#include <limits.h>\n",
      "#undef ", fname, "\n",
      """/* The GNU C library defines this for functions which it implements
    to always fail with ENOSYS.  Some functions are actually named
    something starting with __ and the normal name is an alias.  */
#if defined __stub_""", fname, " || defined __stub___", fname, "\n", """
choke me
#endif
"""
    ].}  #""" <- for code lint
    proc function(): cchar{.importc, cdecl.}
    discard function()

template AC_CHECK_FUNC*(function) =
  AC_CHECK_FUNC(`HAVE function`, function)


macro AC_CHECK_FUNCS*(functions: varargs[untyped]): untyped =
  result = newStmtList()
  for fun in functions:
    result.add quote do:
      AC_CHECK_FUNC(`fun`)
