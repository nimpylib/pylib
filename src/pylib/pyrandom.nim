import std/random
export random

template seed*() = randomize()
template seed*(val: SomeNumber) = randomize(int(val))
template choice*[T](data: openArray[T]): T = sample(data)
template randint*[T: SomeInteger](a, b: T): int = rand(a .. b)