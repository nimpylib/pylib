## XXX: TODO: current Implementation is slow

import ./nextafter

proc nextafter*(x, y: float;
                         usteps: uint64): float =
  result = x
  for _ in 1..usteps:
    result = nextafter(result, y)

