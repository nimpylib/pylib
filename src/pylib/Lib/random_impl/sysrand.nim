
import std/options
from std/math import pow
import ./types
#import ./[proc_dispatched, proc_others]
from ../os import urandom
import ../../numTypes/ints 
from ../../pyerrors/rterr import NotImplementedError

type
  PySysRandom* = ref object of PyRandom

proc SysRandom*(): PySysRandom = PySysRandom Random()
proc SysRandom*(seed: int64): PySysRandom = PySysRandom Random(seed)

const
  BPF = 53        # Number of bits in a float
  RECIP_BPF = pow(float(2), -BPF) ## 2 ** -BPF

using self: PySysRandom

method random*(self): float =
  ## Get the next random number in the range 0.0 <= X < 1.0.
  float(int.from_bytes(urandom(7)) shr 3) * RECIP_BPF

template raise_ValueError(msg) = raise newException(ValueError, msg)

method getrandbits*(self; k: int): int =
  if k < 0:
    raise_ValueError("number of bits must be non-negative")
  let
    numbytes = (k + 7) div 8                       # bits / 8 and rounded up
    x = int.from_bytes(urandom(numbytes))
  return x shr (numbytes * 8 - k)                # trim excess bits

method randbytes*(self; n: int): string =
  # os.urandom(n) fails with ValueError for n < 0
  # and returns an empty bytes string for n == 0.
  urandom(n)

method seed*(self; _ = none(int64)) =
  ## Stub method.  Not used for a system random number generator."
  discard

## Method should not be called for a system random number generator.
template notimplemented =
  raise newException(NotImplementedError, 
    "System entropy source does not have state.")

method getstate*(self): PyRandomState = notimplemented
method setstate*(self; _: PyRandomState) = notimplemented
