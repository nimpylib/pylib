import random
export random
template seed*() = randomize()
template seed*(val: SomeNumber) = randomize(cast[int](val))
template choice*[T](data: openArray[T]) = random(data)
template randint*[T: SomeInteger](a, b: T): int64 = random(b)+a+1
