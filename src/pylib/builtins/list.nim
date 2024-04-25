## Python's `list` with its methods and `sorted` buitin


# Currently, we use Nim's `seq` to minic list.
# 
# NOTE: Nim's `seq` is continuous, while CPython's `list` is linked.


from std/algorithm import reverse, sort, SortOrder, sortedByIt, sorted

from ./iters import enumerate
import ../collections_abc

export index, count

# Impl begin (PyList impl)

export sorted, reverse  # for openArray

type
  PyList*[T] = object
    data: seq[T]
  ## Currently is an alias of seq. shall be distinct type, as some routiues has different signature
  ##  for example, `seq[T].insert(T, int)` and `list[T].insert(int, T)`

converter asSeq[T](self: PyList[T]): seq[T] = self.data
converter asSeq[T](self: var PyList[T]): var seq[T] = self.data

iterator items*[T](self: PyList[T]): T =
  for i in self.data:
    yield i

template len*(self: PyList): int = system.len(asSeq self)

template normIdx(idx, ls): untyped =
  (if ord(idx) < 0: ls.len+idx else: idx)

func `[]=`*[T](self: var PyList[T], idx: int, x: T) =
  system.`[]=`(self.asSeq, normIdx(idx, self), x)
func `[]`*[T](self: PyList[T], idx: int): T =
  system.`[]`(self.asSeq, normIdx(idx, self))

func `==`*[T](self: PyList[T], o: PyList[T]): bool = self.asSeq == o.asSeq
func `==`*[T](self: PyList[T], o: seq[T]): bool = self.asSeq == o
func `==`*[T](self: PyList[T], o: openArray[T]): bool = self.asSeq == @o

template `==`*[T](o: seq[T], self: PyList[T]): bool = `==`(self, o)
template `==`*[T](o: openArray[T], self: PyList[T]): bool = `==`(self, o)


func newPyList[T](s: seq[T]): PyList[T] = result.data = s
template newPyList[T](len=0): untyped = newPyList newSeq[T](len)

func reverse*(self: PyList) = reverse(self.asSeq)

func append*[T](self: var PyList[T], x: T) = self.asSeq.add x

func extend*[T](self: var PyList[T], ls: openArray[T]) =
  self.asSeq.add ls

template extend*[T](self: var PyList[T], ls: Iterable[T]) =
  for i in ls:
    self.append(i)

func insert*[T](self: var PyList[T], idx: int, x: T) =
  if idx > self.len:
    self.append(x)
  else:
    system.insert(self.asSeq, x, normIdx(idx, self))

func delitem*(self: var PyList, idx: int) =
  self.asSeq.delete normIdx(idx, self)

func clear*(self: var PyList) =
  self.asSeq.setLen 0

template rev2ord(reverse: bool): algorithm.SortOrder =
  if reverse: Descending
  else: Ascending

func sort*[T](self: var PyList[T], reverse=false) =
  ## list.sort(reverse=False)
  self.asSeq.sort(order=rev2ord(reverse))

func sorted*[T](self: PyList[T], reverse=false): PyList[T] =
  ## sorted(list, reverse=False)
  newPyList self.asSeq.sorted(order=rev2ord(reverse))

# Impl end

# the following does nothing with how PyList is implemented.

func list*[T](): PyList[T] =
  runnableExamples:
    assert len(list[int]()) == 0
  newPyList[T]()

func `*`*[T](n: Natural, ls: PyList[T]): PyList[T] =
  for i in 0..n:
    result.extend ls

template `*`*[T](ls: PyList[T], n: Natural): PyList[T] =
  ls * n

template `+`*[T](self: var PyList[T], x: PyList[T]): PyList[T] =
  self.extend x

# it has side effects as it may call `items`
proc list*[T](iter: Iterable[T]): PyList[T] =
  when iter is Sized:
    result = newPyList[T](len(iter))
    for i, v in enumerate(iter):
      result[i] = v
  else:
    for i in iter:
      result.append(i)

func `$`*(ls: PyList): string =
  if len(ls) == 0: return "[]"

  result.add "[" & $ls[0]
  for i in 1..<ls.len:
    result.add ", " & $ls[i]
  result.add ']'

type
  SortKey[K] = object of RootObj
    key: K
  SortIdx[K] = object of SortKey[K]
    idx: int
  SortItem[T, K] = object of SortKey[K]
    data: T

func cmpKey[T; S: SortKey[T]](a, b: S): int = cmp(a.key, b.key)

template seqSortWithKeyImpl[T, K](
      target, source;
      # if write as following, will 
      #  `SIGSEGV: Illegal storage access. (Attempt to read from nil?)`
      #  when compiling
      # target: MutableSequence[T], source: Sequence[T];
     reverse: bool; same: static[bool]) =
  # target, source cannot be one obj, unless `same` is true
  # target must be lager or equal than source
  bind cmpKey
  mixin key
  template sameOr(a,b): untyped =
    when same: a else: b
    
  when same:
    var temp = newSeq[SortItem[T, K]](len(source))
  else:
    var temp = newSeq[SortIdx[K]](len(source))
  for i, v in enumerate(source):
    temp[i] = sameOr(
      SortItem[T, K](key: key(v), data: v),
      SortIdx[K](key: key(v), idx: i)
    )
  temp.sort(cmp=cmpKey, order=rev2ord(reverse))
  for i, t in temp:
    target[i] = sameOr(t.data, source[t.idx])

template iterSortWithKeyImpl[T, K](
   target; source;
   #target: MutableSequence[T], source: not Sequence[T] and Iterable[T];
   reverse: bool) =
  # target, source can be one obj
  # target will be overwritten.
  bind cmpKey
  mixin key
  var temp: seq[SortItem[T, K]]
  var mIdx = 0
  for v in source:
    temp.add SortItem(key: key(v), data:v)
    mIdx.inc
  temp.sort(cmp=cmpKey, order=rev2ord(reverse))
  const canSetLen = compiles(target.setLen(1))
  when canSetLen:
    target.setLen(mIdx)
    for i, t in temp:
      target[i] = t.data
  else:
    for t in temp:
      target.append(t.data)

proc sort*[T, K](self: var PyList[T],
    key: proc (x: T): K, reverse=false) =
  ## list.sort(key, reverse=False)
  seqSortWithKeyImpl[T, K](self, self, reverse, same=true)

func sorted*[T, K](x: Sequence[T],
    key: proc (x: T): K, reverse=false): PyList[T] =
  result = newPyList[T](len(x))
  seqSortWithKeyImpl[T, K](result, x, reverse, same=false)

func sorted*[T, K](x: not Sequence[T] and Iterable[T],
    key: proc (x: T): K, reverse=false): PyList[T] =
  result = newPyList[T]()
  iterSortWithKeyImpl[T, K](result, x, reverse)