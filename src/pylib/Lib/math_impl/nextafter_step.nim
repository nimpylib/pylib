

from ./isX import isnan

proc nextafter*(x, y: float;
                         usteps: uint64): float =
  ## [clinic input]
  ## math.nextafter
  ##
  ##     x: double
  ##     y: double
  ##     /
  ##
  ##     steps: object = None
  ##
  ## Return the floating-point value the given number of steps after x towards y.
  ##
  ## If steps is not specified or is None, it defaults to 1.
  ##
  ## Raises a TypeError, if x or y is not a double, or if steps is not an integer.
  ## Raises ValueError if steps is negative.
  ## [clinic start generated code]
  ## [clinic end generated code: output=cc6511f02afc099e input=7f2a5842112af2b4]
  when defined(aix):
    if x == y:
      ##  On AIX 7.1, libm nextafter(-0.0, +0.0) returns -0.0.
      ##            Bug fixed in bos.adt.libm 7.2.2.0 by APAR IV95512.
      return (y)
    if isnan(x):
      return (x)
    if isnan(y):
      return (y)

  ##  Conveniently, uint64_t and double have the same number of bits
  ##  on all the platforms we care about.
  ##  So if an overflow occurs, we can just use UINT64_MAX.

  if usteps == 0:
    return x
  if isnan(x):
    return x
  if isnan(y):
    return y
  type
    pun {.union.} = object # XXX: TODO: union object cannot run when nimvm
      f: float64
      i: uint64

  var
    ux = pun(f: x)
    uy = pun(f: y)
  if ux.i == uy.i:
    return x
  const sign_bit = 1'u64 shl 63
  let
    ax: uint64 = ux.i and not sign_bit
    ay: uint64 = uy.i and not sign_bit
  ##  opposite signs
  if bool((ux.i xor uy.i) and sign_bit):
    ##  NOTE: ax + ay can never overflow, because their most significant bit
    ##  ain't set.
    if ax + ay <= usteps:
      return uy.f
      ##  This comparison has to use <, because <= would get +0.0 vs -0.0
      ##  wrong.
    elif ax < usteps:
      let res = pun(i: (uy.i and sign_bit) or (usteps - ax))
      return res.f
    else:
      dec(ux.i, usteps)
      return ux.f
  elif ax > ay: ##  same sign
    if ax - ay >= usteps:
      dec(ux.i, usteps)
      return ux.f
    else:
      return uy.f
  else:
    if ay - ax >= usteps:
      inc(ux.i, usteps)
      return ux.f
    else:
      return uy.f

when culonglong is_not uint64:
  proc nextafter*(x, y: float;
                          usteps_ull: culonglong): float =
    let usteps =
      if usteps_ull >= UINT64_MAX:
        ##  This branch includes the case where an error occurred, since
        ##  (unsigned long long)(-1) = ULLONG_MAX >= UINT64_MAX. Note that
        ##  usteps_ull can be strictly larger than UINT64_MAX on a machine
        ##  where unsigned long long has width > 64 bits.
        UINT64_MAX
      else:
        cast[uint64](usteps_ull)
    nextafter(x, y, uint64 ustep)

func nextafter*(x, y: float;
                         steps: int): float =
  if steps < 0:
    raise newException(ValueError, "steps must be a non-negative integer")
  nextafter(x, y, uint64 steps)
