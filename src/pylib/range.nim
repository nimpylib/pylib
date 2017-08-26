import sequtils

iterator range*[T](start, stop: T, step: int, dummy = false): T = 
  ## Python-like range iterator
  ## Supports negative values!
  # dummy is used to distinguish iterators from templates, so
  # templates wouldn't end in an endless recursion
  assert(step != 0, "Step must not be zero!")
  if step > 0 and stop > 0:
    for x in countup(start, stop - 1, step):
      yield x
  elif step < 0:
    for x in countdown(start, stop + 1, -step):
      yield x

iterator range*[T](start, stop: T, dummy = false): T =
  for x in start..<stop: 
    yield x

iterator range*[T](stop: T, dummy = false): T = 
  for x in T(0)..<stop:
    yield x

# Templates for range so you don't need to use toSeq manually
template range*[T](start, stop: T, step: int): seq[T] = toSeq(range(start, stop, step, true))
template range*[T](start, stop: T): seq[T] = toSeq(range(start, stop, true))
template range*[T](stop: T): seq[T] = toSeq(range(stop, true))