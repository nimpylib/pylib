

func `@=`*[T](p1, p2: ref T): bool =
  ## cmp on addr of pointers
  cast[pointer](p1) == cast[pointer](p2)
