## Lib/math

#import ../version

import ./n_math
export n_math except py_math_isclose_impl,
  fmod, ldexp

from ./math_patch/err import raiseDomainErr, raiseRangeErr
from ./math_patch/errnoUtils import CLike

func fmod*(x: SomeNumber, y: SomeNumber): float =
  result = n_math.fmod(x, y)
  if isnan(result):
    raiseDomainErr()

func ldexp*(x: SomeFloat, i: int): float =
  var exc: ref Exception
  result = ldexp(x, i, exc)
  if exc.isNil: return
  raise exc
