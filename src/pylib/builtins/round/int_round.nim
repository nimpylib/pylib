
from ../../ops import divmod, `**`, `%`

func round*(x: int): int = x

func divmodNear(a, b: int): tuple[q, r: int] =
  var (q, r) = divmod(a, b)

  # round up if either r / b > 0.5, or r / b == 0.5 and q is odd.
  # The expression r / b > 0.5 is equivalent to 2 * r > b if b is
  # positive, 2 * r < b if b negative.
  let
    greater_than_half = if b > 0: 2*r > b else: 2*r < b
    exactly_half = 2*r == b
  if greater_than_half or exactly_half and q % 2 == 1:
      q += 1
      r -= b
  return (q, r)

func round*(x: int, ndigit: int): int =
  if ndigit >= 0: return x
  x - divmodNear(x, 10 ** -ndigit).r
