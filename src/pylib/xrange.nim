import std/[strutils, math]

type
  Range*[T] = object ## Python-like range object
    start, stop: T
    step, len: int

func `$`*[T](rng: Range[T]): string =
  if rng.step != 1:
    "range($1, $2, $3)".format(rng.start, rng.stop, rng.step)
  else:
    "range($1, $2)".format(rng.start, rng.stop)

func xrange*[T: SomeInteger](start, stop: T, step: int): Range[T] =
  ## Creates new range object with given *start* and *stop* of any integer type
  ## and *step* of int
  if unlikely(step == 0):
    raise newException(ValueError, "range() arg 3 must not be zero!")
  result.start = start
  result.stop = stop
  result.step = step
  result.len = int(math.ceil((stop - start) / step))

template xrange*[T: SomeInteger](start, stop: T): Range[T] =
  ## Shortcut for range(start, stop, 1)
  xrange(start, stop, 1)

template xrange*[T: SomeInteger](stop: T): Range[T] =
  ## Shortcut for range(0, stop, 1)
  xrange(0, stop)

template len*[T](rng: Range[T]): int =
  rng.len

iterator items*[T](rng: Range[T]): T =
  var res = rng.start
  if rng.step > 0:
    while res <= (rng.stop - 1):
      yield res
      res += rng.step
  else:
    let opposite = -rng.step
    while res >= (rng.stop + 1):
      yield res
      res -= opposite

func contains*[T](x: Range[T], y: T): bool =
  ## Checks if given value is in range
  result =
    if x.step > 0:
      y >= x.start and y < x.stop
    else:
      y > x.stop and y <= x.start
  result = result and ((y - x.start) mod x.step == 0)

func `[]`*[T](x: Range[T], y: Natural): T {.inline.} =
  ## Get value from range by its index
  assert y < x.len, "Index out of bounds"
  result = x.start + (x.step * y)

func min*[T](x: Range[T]): T {.inline.} =
  ## Get minimum value from range
  x[if x.step > 0: 0 else: x.len - 1]

func max*[T](x: Range[T]): T {.inline.} =
  ## Get maximum value from range
  x[if x.step > 0: x.len - 1 else: 0]

func list*[T](x: Range[T]): seq[T] =
  ## Generate sequence of numbers from given range
  result = newSeq[T](x.len)
  var i = 0
  for val in x:
    result[i] = val
    inc i
