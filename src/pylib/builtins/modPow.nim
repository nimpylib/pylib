# `pow` with mod, imported by `./mathfunc`

import std/math
import std/bitops

func long_invmod(aa, nn: int): int =

  # translated from CPython3.10.5 `Objetcs/longobject.c` `long_invmod`
  var
    a = aa
    n = nn
  
  # Should only ever be called for positive n
  assert n > 0

  var b = 1
  var c = 0

  while n != 0:
    let
      q = floorDiv(a, n)
      r = floorMod(a, n)
    a = n
    n = r
    let t = q * c
    let s = b - t

    b = c
    c = s

  if a != 1:
    # a != 1 we don't have an inverse.
    raise newException(ValueError,
                    "base is not invertible for the given modulus")
  # a == 1; b gives an inverse modulo n
  return b

type Long = int  ## XXX: current only used in `table`

const FIVEARY_CUTOFF = 8

type Digit = uint8

const BitPerByte = 8

func bit_length(x: SomeInteger): int =
  sizeof(x) * BitPerByte - bitops.countLeadingZeroBits x
  
# Py_SIZE
template get_ob_size(x): int = ceilDiv(x.bit_length(), sizeof(Digit)*BitPerByte)

template get_ob_digit(x, i): Digit = cast[UncheckedArray[Digit]](x)[i]

# XXX: PyLong_SHIFT is 15 or 30
const Long_SHIFT = sizeof(Digit) * BitPerByte - 1 # 7

func long_pow(v, w, x: int): int =
  
  # translated from CPython3.10.5 `Objetcs/longobject.c` `long_pow`
  var (a, b, c) = (v, w, x)
  var negativeOutput = false # if x<0 return negative output

  if c == 0:
    raise newException(ValueError, "pow() 3rd argument cannot be 0")
  elif c < 0:
    negativeOutput = true
    c = -c
  elif c == 1:
    return 0

  #[ if exponent is negative, negate the exponent and
    replace the base with a modular inverse ]#
  if b < 0:
    b = -b
    a = long_invmod(a, c)

  #[ Reduce base by modulus in some cases:
    1. If base < 0.  Forcing the base non-negative makes things easier.
    2. If base is obviously larger than the modulus.  The "small
      exponent" case later can multiply directly by base repeatedly,
      while the "large exponent" case multiplies directly by base 31
      times.  It can be unboundedly faster to multiply by
      base % modulus instead.
    We could _always_ do this reduction, but 
      we can also do it when it buys something. ]#
  if (a < 0 or a > c):
    a = floorMod(a, c)
  
  var z = 1  # accumulated result
  template REDUCE(X) =
    #[ Perform a modular reduction, X = X % c  /* , but leave X alone if c
      is not given. */ (Currently `c` is always given) ]#
    X = floorMod(X, c)
  template MULT(X, Y, result) =
    #[ Multiply two values, then reduce the result:
      result = X*Y % c.
      /* If c is NULL, skip the mod. */ (Currently `c` is always given) ]#
    result = X*Y
    REDUCE(result)

  let bs = b.get_ob_size()
  if bs <= FIVEARY_CUTOFF:
    # Left-to-right binary exponentiation (HAC Algorithm 14.79)
    # http://www.cacr.math.uwaterloo.ca/hac/about/chap14.pdf
    for i in countdown(bs-1, 0):
      let bi = b.get_ob_digit i
      for ji in countdown(Long_SHIFT, 0):
        MULT(z, z, z)
        if bi.testBit(ji):
          MULT(z, a, z)

  else:
    # XXX: Currently this branch is impossible
    #   as we don't use variable-length integer in Nim

    #[ 5-ary values.  If the exponent is large enough, table is
     * precomputed so that table[i] == a**i % c for i in range(32).
     ]#
    var table: array[32, Long]

    #[ Left-to-right 5-ary exponentiation (HAC Algorithm 14.82) ]#
    table[0] = z
    for i in 1..31:
      MULT(table[i-1], a, table[i])

    for i in countdown(bs - 1, 0):
      let bi = b.get_ob_digit i

      for j in countdown(Long_SHIFT - 5, 0, 5):
        let index = (bi shr j.Digit) and 0x1f
        for k in 0..<5:
          MULT(z, z, z)
        if index != 0:
          MULT(z, table[index], z)

  if negativeOutput and z != 0:
    z = z - c
  result = z

func pow*(base, exp, modulo: int): int =
  runnableExamples:
    assert pow(10, 20, 3) == 1  # 10^20 is bigger than `high int64`
    assert pow(7, 2, 13) == 10
    assert pow(7, 20, 13) == 3
    doAssertRaises ValueError:
      discard pow(1000, -2, 2)
      # base is not invertible for the given modulus
    assert pow(1234, 20, 73) == 9
  long_pow(base, exp, modulo)
