

func `@=`*[T](p1, p2: ref T): bool =
  ## cmp on addr of pointers
  system.`==` p1, p2
  # See https://github.com/nim-lang/Nim/issues/23850
  # for why not using cast[pointer](p1) == cast[pointer](p2)
