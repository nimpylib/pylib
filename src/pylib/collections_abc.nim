

type
  Iterable*[T] = concept self  ## Mimic Pythons Iterable.
    for value in self:
      value is T
  Sized* = concept self
    self.len
  
  Container*[T] = concept self
    contains(self, T) is bool
  
  Collection*[T] = concept self of Sized, Container, Iterable
  
  Sequence*[T] = concept self of Collection
    self[int] is T


  
