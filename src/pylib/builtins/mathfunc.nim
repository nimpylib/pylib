
import math
export math.round, math.pow  # pow for float

import ./modPow
export modPow.pow

func pow*(base, exp, modulo: float): int{.error: 
  "TypeError: pow() 3rd argument not allowed unless all arguments are integers".}
  ## raises Error like Python does, but a static error instead of runtime

func pow*(base: int, exp: Natural): int =
  ## .. warning:: `pow` with a negative `exp` shall results in float,
  ##  but for static-type lang it's not possible for a function to return
  ##  either a float or int, except for using a boxing type.
  ## Therefore for `pow(base, exp)`, `exp` cannot be negative.
  
  base ^ exp
  