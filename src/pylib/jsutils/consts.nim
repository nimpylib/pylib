
const
  InNodeJs = defined(nodejs)
import std/jsffi
when InNodeJs:
  let econsts = require("constants")
else:
  let econsts{.importjs: """(await import("node:constants"))""".}: JsObject

template from_js_const*(name; defval: int): int =
  bind econsts, isUndefined, to, `[]`
  let n = econsts[astToStr(name)]
  if n.isUndefined: defVal else: n.to(int)
