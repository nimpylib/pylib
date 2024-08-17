 
from std/math import cos, sin, PI, copySign, classify, FloatClass, `mod`

func sinpi*[F: SomeFloat](x: F): F =
  let fc = classify(x)
  if fc == fcNan or fc == fcInf or fc == fcNegInf: 
    return NaN
  # Argument reduction (reduce to [0,2))
  var r, ar: F
  r = x mod 2.0
  ar = abs(r)

  # If `x` is an integer, the mod is an Integer...
  if ar == 0.0 or ar == 1.0:
    return copySign(0.0, r)
  if ar < 0.25:
    return sin(PI*r)

  # In each pf the following, we further reduce to [-pi/4. pi/4]...
  if ar < 0.75:
    ar = 0.5 - ar
    copySign(cos(PI*ar), r)
  elif ar < 1.25:
    r = copySign(1.0, r) - r
    sin(PI*r)
  elif ar < 1.75:
    ar -= 1.5
    -copySign(cos(PI*ar), r)
  else:
    r -= copySign(2.0, r)
    sin(PI*r)
