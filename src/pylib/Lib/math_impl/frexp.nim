
from ./platformUtils import clikeOr
from ./isX import isnan, isinf
import ./patch/ldexp_frexp/frexp as pure_frexp
import std/math as std_math  # frexp

func n_frexp*(x: SomeFloat): (float, int) = pure_frexp.frexp(x.float)
func n_frexp*(x: SomeFloat, e: var int): float = (result, e) = n_frexp(x.float)

func frexpImpl(x: SomeFloat): (float, int){.inline.} =
  #[ deal with special cases directly, to sidestep platform
      differences ]#
  if isnan(x) or isinf(x) or x == 0:
    return (x, 0)
  result = std_math.frexp(x)

func frexp*(x: SomeFloat): (float, int) =
    clikeOr(
      frexpImpl(x),
      n_frexp(x)
    )

func frexp*(x: SomeFloat; e: var int): float =
  (result, e) = frexp(x)


