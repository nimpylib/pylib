

from ./platformUtils import CLike, clikeOr
import ./patch/nextafter as n_nextafterLib
import ./nextafter_step
from ./isX import isnan, isinf

when CLike:
  {.push header: "<math.h>".}
  proc c_nextafter(frm, to: c_double): c_double{.importc: "nextafter".}
  proc c_nextafter(frm, to: c_float): c_float{.importc: "nextafterf".}
  {.pop.}

func nextafter*[F: SomeFloat](x, y: F): F =
  clikeOr(
    c_nextafter(x, y),
    n_nextafterLib.nextafter(x, y)
  )

func nextafter*[F: SomeFloat](x, y: F; steps: int|uint64): F =
  nextafter_step.nextafter(x, y, steps)

func ulp*[F: SomeFloat](x: F): F =
  bind nextafter
  if isnan(x): return x
  let x = abs(x)
  if isinf(x): return x
  result = nextafter(x, Inf)
  if isinf(result):
    # special case: x is the largest positive representable float 
    result = nextafter(x, NegInf)
    return x - result
  result -= x
