
import ./utils
addPatch((2,3,1), defined(js)):
  # fixes in nim-lang/Nim#24695
  from std/math import isNaN
  func isFinite(x: float): bool{.importc.} # importjs requires a pattern
  proc `$`*(x: SomeFloat): string =
    if isNaN(x): "nan"
    elif not isFinite(x):
      if x > 0: "inf" else: "-inf"
    else: system.`$` x

when not hasBug:
  proc `$`*(x: SomeFloat): string = system.`$`(x)
