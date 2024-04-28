

type
  Iterable*[T] = concept self  ## Mimic Pythons Iterable. But not checks `iter`
    for value in self:
      value is T
  Sized* = concept self
    len(self) is int
  
  Container*[T] = concept self
    contains(self, T) is bool
  
  Collection*[T] = Sized and Container[T] and Iterable[T]
  
  Sequence*[T] = concept self of Collection[T]
    # NIM-BUG: if only a `self[int] is T`,
    #  Nim will wrongly complain `'T' is declared but not used`
    T
    self[int] is T
  MutableSequence*[T] = concept self of Sequence[T]
    T  # NIM-BUG: see above.
    self[int] = T
    self.delitem(int)  ## __delitem__
    self.insert(int, T)  ## insert item before index

func contains*[T](s: Sequence[T], x: T): bool =
  for i in s:
    if x == i: return true

#func reversed*[S: Sequence](s: S): Iterable

func index*[T](s: Sequence[T], x: T, start=0, stop = -1): int =
  let last = if stop == -1: s.len-1 else: stop 
  result = start
  for i in start..last:
    if x == s[i]:
      return result
    result.inc
  raise newException(ValueError, $x & " is not in sequence")

func count*[T](s: Sequence[T], x: T): int =
  for i in s:
    if i == x:
      result.inc

func append*[T](ms: MutableSequence[T], x: T) =
  ms.insert(ms.len, x)

func clear*(ms: MutableSequence) = 
  for i in 0..ms.len:
    ms.delitem(i)
    
func reverse*(ms: MutableSequence) =
  let le = ms.len
  for i in 0 ..< le div 2:
    swap ms[i], ms[le-1-i]

func extend*[T](ms: MutableSequence[T], it: Iterable[T]) =
  for i in it:
    ms.append(i)

func pop*[T](ms: MutableSequence[T]): T =
  let last = ms.len-1
  result = ms[last]
  ms.delitem(last)

func remove*[T](ms: MutableSequence[T], x: T) =
  for i in 0..<ms.len:
    if ms[i] == x:
      ms.delitem(i)
