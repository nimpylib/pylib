
import ./utils
addPatch((2,2,1), defined(js)):
  from std/math import isNaN
  proc `$`*(x: SomeFloat): string =
    if isNaN(x): "nan"
    else: system.`$` x

when not hasBug:
  proc `$`*(x: SomeFloat): string = system.`$`(x)
