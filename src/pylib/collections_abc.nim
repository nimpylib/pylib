

type
  Iterable*[T] = concept self  ## Mimic Pythons Iterable.
    for value in self:
      value is T
  Sized* = concept self
    self.len
  
