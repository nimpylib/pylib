## functions and methods that can be directly dispatched to `std/random`

import std/random
import ./gstate
import ./macroutils
import ./justLessThanOneConst

using self: PyRandom
template rnd: untyped = self.getmstate()

# methods with self are in ./types
proc getstate*(): PyRandomState = gRand
proc setstate*(state: PyRandomState) = gRand = state

genGbls:
  proc seed*(self) = self.setstate initRand()
  func seed*(self; val: SomeInteger) = rnd.initRand int64 val

  func choice*[T](self; data: openArray[T]): T = rnd.sample(data)

  func genrand_uint32*(self): uint32 = rnd.rand uint32  ## inner.
  func randbelow*[T: SomeInteger](self; n: T): T = rnd.rand n  ## `_randbelow`  inner.

  func randint*[T: SomeInteger](self; a, b: T): T = rnd.rand(a .. b)

  func randrange*[T: SomeInteger](self; stop: T): T = rnd.rand stop
  func randrange*[T: SomeInteger](self; start, stop: T): T = rnd.rand start..<stop

  #template randrange*[T: SomeInteger](start, stop: T; step: int): T =

  func random*(self): float = rnd.rand justLessThanOne

  func uniform*(self; a, b: float): float = rnd.rand a..b
  
  func guass*(self; mu = 0.0, sigma = 1.0): float = rnd.gauss mu, sigma
