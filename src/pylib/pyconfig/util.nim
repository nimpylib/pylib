
import std/fenv
import std/os

const debug{.booldefine.} = false

const weirdTarget = defined(js) or defined(nimscript)

const cacheDir = currentSourcePath()/../".cfgcache"
when not weirdTarget:
  static:
    createDir cacheDir # noop if cacheDir dirExists
template cfgCache(fn): string = cacheDir/fn
template decl_ac_impl(subcmd; variable; defval; code) =
  when weirdTarget:
    const variable* = defval
  else:
    const fp = cfgCache astToStr variable
    const variable* = static:
      if fileExists fp: fp.slurp == "1"
      else:
        let res = gorgeEx( "nim " & subcmd & " --hints:" & $debug & " --eval:" & quoteShell(astToStr code) )
        fp.writeFile $res.exitCode
        bool res.exitCode

template AC_LINK_IFELSE*(variable, defval, code) = decl_ac_impl('c', variable, defval, code)
template AC_RUN_IFELSE*(variable, defval, code) = decl_ac_impl('r', variable, defval, code)
