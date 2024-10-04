
from ./platformUtils import clikeOr
from ./isX import isnan, isinf
import ./patch/ldexp_frexp/frexp as pure_frexp
import std/math as std_math  # frexp

func n_frexp*[F: SomeFloat](x: F): (F, int) = pure_frexp.frexp(x)
func n_frexp*[F: SomeFloat](x: F, e: var int): F = (result, e) = n_frexp(x)

func frexpImpl[F](x: F): (F, int){.inline.} =
  #[ deal with special cases directly, to sidestep platform
      differences ]#
  if isnan(x) or isinf(x) or x == 0:
    return (x, 0)
  result = std_math.frexp(x)

func frexp*[F: SomeFloat](x: F): (F, int) =
    clikeOr(
      frexpImpl(x),
      n_frexp(x)
    )

func frexp*[F: SomeFloat](x: F; e: var int): F =
  (result, e) = frexp(x)


