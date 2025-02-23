
import ./iters

type
  Sized* = concept self
    len(self) is int
  
  Container*[T] = concept self
    # NIM-BUG: if only a `contains(self, T) is bool`,
    #  Nim will wrongly complain `'T' is declared but not used`
    T
    contains(self, T) is bool
  
  Collection*[T] = Sized and Container[T] and Iterable[T]
  
  Sequence*[T] = concept self of Collection[T]
    T  # NIM-BUG: see above.
    self[int] is T
  MutableSequence*[T] = concept self of Sequence[T]
    T  # NIM-BUG: see above.
    self[int] = T
    self.delitem(int)  ## __delitem__
    self.insert(int, T)  ## insert item before index

  Mapping*[K, V] = concept self of Collection[K]
    K  # NIM-BUG: see above.
    V
    self[K] is V


when not defined(js) or (NimMajor, NimMinor, NimPatch) > (2, 1, 0):
  # NIM-BUG
  func contains*[T](s: Container[T], x: T): bool =
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

template useOr(use, els): untyped =
  when compiles(use): use
  else: els

template newSeqMayUninit[T](len): seq[T] =
  useOr newSeqUninit[T](len), newSeq[T](len)

func `@`*[T](s: Sequence[T]): seq[T]{.noInit, inline.} =
  ## EXT. stable.
  result = newSeqMayUninit[T](s.len)
  var i = 0
  for ele in s:
    result[i] = ele
    i.inc

func append*[T](ms: MutableSequence[T], x: T) =
  ms.insert(ms.len, x)

func clear*(ms: MutableSequence) = 
  for i in 0..<ms.len:
    ms.delitem(i)
    
func reverse*(ms: MutableSequence) =
  let le = ms.len
  for i in 0 ..< le div 2:
    swap ms[i], ms[le-1-i]

func extend*[T](ms: MutableSequence[T], it: Iterable[T]) =
  for i in it:
    ms.append(i)

func pop*[T](ms: MutableSequence[T], index = -1): T =
  let idx = if index < 0: ms.len + index else: index
  result = ms[idx]
  ms.delitem(idx)

func remove*[T](ms: MutableSequence[T], x: T) =
  for i in 0..<ms.len:
    if ms[i] == x:
      ms.delitem(i)

template keys*[K, V](m: Mapping[K, V]): untyped = system.items(m)

iterator values*[K, V](m: Mapping[K, V]): V =
  for k in m.keys(): yield m[k]
iterator items*[K, V](m: Mapping[K, V]): (K, V) =
  for k in m.keys(): yield (k, m[k])

func contains*[K, V](m: Mapping[K, V], k: K): bool =
  for i in m.keys():
    if k == i: return true

func get*[K, V](m: Mapping[K ,V], key: K): V = m[key]
func get*[K, V](m: Mapping[K ,V], key: K, default: V): V =
  if key in m: m[key]
  else:default

func `==`*[K, V](a, b: Mapping[K, V]): bool =
  if len(a) != len(b): return false
  for k, v in a.items():
    if b[k] != v:
      return false
  return true
