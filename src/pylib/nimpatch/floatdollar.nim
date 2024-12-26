
import ./utils
const M = int.high
addPatch((M,M,M), defined(js)):
  from std/math import isNaN
  proc `$`*(x: SomeFloat): string =
    if isNaN(x): "nan"
    else: system.`$` x

when not hasBug:
  proc `$`*(x: SomeFloat): string = system.`$`(x)
