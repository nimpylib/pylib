##
## c_fma means compatible fma, using `<math.h>` `fma` when for C

from ../platformUtils import CLike
from ../isX import isfinite, isnan

when CLike:
  const UNRELIABLE_FMA* = true
  {.push header: "<math.h>".}
  proc c_fma*(x, y, z: cdouble): cdouble{.importc: "fma".}
  proc c_fma*(x, y, z: cfloat): cfloat{.importc: "fmaf".}
  {.pop.}

else:
  const UNRELIABLE_FMA* = false
  func c_fma*[F: SomeFloat](x, y, z: F): F =
    #{.error: "not impl for weird target".}
    {.warning: "not accurate for weird target".}
    x * y + z

func fma*[F: SomeFloat](x, y, z: F, exc: var ref Exception): F{.raises: [].} =
  ## EXT.
  result = c_fma(x, y, z)

  # Fast path: if we got a finite result, we're done.
  if isfinite(result):
    return result
  template all3(f): bool =
    f(x) and f(y) and f(z)
  template notNaN(x): bool = not isnan(x)

  # Non-finite result. Raise an exception if appropriate, else return r.
  if isnan(result):
    if all3 notNaN:
      # NaN result from non-NaN inputs.
      exc = newException(ValueError, "invalid operation in fma")
      return
  elif all3 isfinite:
    exc = newException(OverflowDefect, "overflow in fma")
    return
func fma*[F: SomeFloat](x, y, z: F): F{.raises: [].} =
  ## .. warning:: this fma does not touch errno and exception is discarded
  var exc_unused: ref Exception
  fma(x, y, z, exc_unused)
