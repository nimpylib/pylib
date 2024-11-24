
const CLike* = defined(c) or defined(cpp) or defined(objc)

template clikeOr*(inCLike, b): untyped =
  # for nimvm-able expr
  bind CLike
  when nimvm: b
  else:
    when CLike: inCLike
    else: b

template impJsOrC*(sym, cfloatSym, argSym){.dirty.} =
  bind CLike
  when defined(js):
    func sym(argSym: float): float{.importjs: "Math." & astToStr(sym) & "(#)".}
    func sym(argSym: float32): float32 = float32(sym(float argSym))
  elif CLike:
    {.push header: "<math.h>".}
    func sym(arg: c_double): c_double{.importc.}
    func cfloatSym(arg: c_float): c_float{.importc.}
    {.pop.}
    func sym(argSym: float): float = float sym(arg=c_double(argSym))
    func sym(argSym: float32): float32 = float32 cfloatSym c_float(argSym)
  else:
    {.error: "unreachable".}


