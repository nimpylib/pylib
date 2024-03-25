import std/random
export random

proc Random*(): Rand = initRand()
proc Random*(x: int64): Rand = initRand(x)

var gRand = Random()

template seed*() = discard
template seed*(val: SomeNumber) =
  bind gRand
  gRand = initRand(int64(val))

template choice*[T](data: openArray[T]): T = gRand.sample(data)
template randint*[T: SomeInteger](a, b: T): int = grand.rand(a .. b)