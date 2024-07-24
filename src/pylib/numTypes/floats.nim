
import std/math
import ../pystring/strimpl
import ./floats/[init]
export init.float

func hex*(x: float): PyStr =
  str x.hexImpl


func isfinite(x: SomeFloat): bool =
  let cls = classify(x)
  cls != fcInf and cls != fcNegInf and cls != fcNan
func is_integer*(self: float): bool =
  if not self.isfinite: false
  else: floor(self) == self
