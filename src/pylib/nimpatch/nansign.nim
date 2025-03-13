{.used.}
import ./utils
addPatch((2,3,1), defined(c) or defined(cpp)):
  # fixes in nim-lang/Nim#24774
  from std/os import quoteShell  # compileTime only
  const HUGE_ENUF = "1e+300"

  template use(s: string; optPre: char) =
    {.passC: optPre&"DNAN=" & quoteShell(s).}

  template useBltin(optPre = '-'){.used.} =
    ## use `__builtin_nanf` which is faster, if available
    use """(__builtin_nanf(""))""", optPre
  template useCaled(optPre = '-'){.used.} =
    const NAN_INFINITY = "((float)("&HUGE_ENUF&'*'&HUGE_ENUF&"))"
    use "(-(float)("&NAN_INFINITY&"*0.0F))", optPre
  when defined(gcc): useBltin
  elif defined(clang):
    # XXX: check "__has_builtin (__builtin_nanf)" is hard here,
    #  we just use fallback
    useCaled
  elif defined(vcc):
    useCaled'/'
  else:
    useCaled
