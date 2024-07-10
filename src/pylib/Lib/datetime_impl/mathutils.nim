

func divmod*[I](x: I, y: Natural, r: var I): I =
  ## returns floorDiv(x, y)

  ##[Compute Python divmod(x, y), returning the quotient and storing the
remainder into *r.  The quotient is the floor of x/y, and that's
the real point of this.  C will probably truncate instead (C99
requires truncation; C89 left it implementation-defined).
Simplification:  we *require* that y > 0 here.  That's appropriate
for all the uses made of it.  This simplifies the code and makes
the overflow case impossible (divmod(LONG_MIN, -1) is the only
overflow case).]##
  result = x div y
  r = x - result * y
  if r < 0:
    result.dec
    r.inc y
  assert 0 <= r and r < y
