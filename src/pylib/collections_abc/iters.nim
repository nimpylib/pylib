

const
  NimVer = (NimMajor, NimMinor, NimPatch)
  ## ? not sure
  SupportIteratorHit = NimVer >= (2, 1, 2) and NimVer < (2, 1, 9)

const ItemTypeMode = typeOfIter
type
  Iterable*[T] = concept self  ## Mimic Pythons Iterable. But not checks `iter`
    #for value in self: value is T 
    # Above may cause inner error when JS backend on older Nim
    T  # see below
    when SupportIteratorHit:
      iterator items(self): T
    else:
      #typeof(self.items(), typeOfIter) is T
      when defined(js):
        typeof(self.items(), ItemTypeMode) is T
      else:
        for value in self: value is T 
  Iterator*[T] = concept self of Iterable[T]
    T
    self.next is T

