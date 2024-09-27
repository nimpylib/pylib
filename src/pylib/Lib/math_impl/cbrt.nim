
from ./platformUtils import CLike
import ./comptime/cbrt as cbrtLib

when CLike:
  {.push header: "<math.h>".}
  proc c_cbrt(x: cdouble): cdouble{.importc: "cbrt".}
  proc c_cbrt(x: cfloat): cfloat{.importc: "cbrtf".}
  {.pop.}
elif defined(js):
  proc c_cbrt(x: cdouble): cdouble{.importjs: "Math.cbrt(#)".}
  proc c_cbrt(x: cfloat): cfloat = cfloat(c_cbrt(cdouble(x)))

#[
proc round_cbrt[F: SomeFloat](x: F): F{.compileTime.} =
  result = x
  var sign = 1.0
  if x < 0.0:
    sign = -1.0
    result = -result
  result = sign * pow(x, 1/3)
]#

func cbrt*[F: SomeFloat](x: F): F =
  when nimvm: cbrtLib.cbrt(x)
  else: c_cbrt(x)

