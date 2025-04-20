## Python's `list` with its methods and `sorted` buitin
##
## LIMIT: `slice` literal is not supported.
## `ls[1:3]` has to be rewritten as `ls[1..2]`

from std/algorithm import reverse, sort, SortOrder, sortedByIt, sorted

from ./iters import enumerate
import ./private/[mathutils, strIter]
import ./pyslice, ./pyrange
import ../collections_abc
import ../mutSeqSliceOp

export index, count

# Impl begin (PyList impl)

export sorted, reverse  # for openArray

import ./list_decl

export list_decl except asSeq
converter nimArrayAsList*[T; I](arr: array[I, T]): PyList[T] =
  newPyList[T](arr)

template len*(self: PyList): int = system.len(asSeq self)

template normIdx(idx, ls): untyped =
  (if ord(idx) < 0: ls.len+idx else: idx)

func `[]=`*[T](self: var PyList[T], idx: int, x: T) =
  system.`[]=`(self.asSeq, normIdx(idx, self), x)
func `[]`*[T](self: PyList[T], idx: int): T =
  system.`[]`(self.asSeq, normIdx(idx, self))

func `[]=`*[T](self: var PyList[T], s: HSlice, x: openArray[T]) =
  system.`[]=`(self.asSeq, s, x)
func `[]=`*[T](self: var PyList[T], s: HSlice, x: PyList[T]) =
  system.`[]=`(self.asSeq, s, x.asSeq)

func `[]=`*[T](self: var PyList[T], s: BackwardsIndex, x: T) =
  system.`[]=`(self.asSeq, s, x)

proc list*[T](iter: Iterable[T]): PyList[T] # front decl
func `[]=`*[T](self: var PyList[T], s: HSlice, x: Iterable[T]) =
  self[s] = list(x)


func normSlice(s: PySlice, le: int): PySlice =
  template norm(idx: int): untyped =
    (if idx < 0: le+idx else: idx)
  slice(s.start.norm, s.stop.norm, s.step)

func `[]=`*[T](self: var PyList[T], s: PySlice, x: Sequence[T]) =
  let s = normSlice(s, self.len)
  if s.step == 1:
    self[s.toNimSlice] = x
    return
  let sliceLen = rangeLen(s.start, s.stop, s.step)
  if x.len != sliceLen:
    raise newException(ValueError,
      "attempt to assign sequence of size " & $x.len &
      " to extended slice of size " & $sliceLen)
  var ord = 0
  for i in pyrange.range(s.start, s.stop, s.step):
    self[i] = x[ord]
    ord.inc
func `[]=`*[T](self: var PyList[T], s: PySlice,
    x: not Sequence[T] and Iterable[T]) =
  var sequ: seq[T]
  for i in x: sequ.add i
  self[s] = sequ

func append*[T](self: var PyList[T], x: T) = self.asSeq.add x
func `+=`*[T](self: var PyList[T], ls: openArray[T]) = self.asSeq.add ls
func `+=`*[T](self: var PyList[T], ls: PyList[T]) = self += ls.asSeq

func `[]`*[T](self: PyList[T], s: HSlice): PyList[T] =
  newPyList system.`[]`(self.asSeq, s)
func `[]`*[T](self: PyList[T], s: BackwardsIndex): T =
  system.`[]`(self.asSeq, s)
# PySlice1 is handled by: converter -> Slice
func `[]`*[T](self: PyList[T], s: PySlice): PyList[T] =
  let s = normSlice(s, self.len)
  if s.step == 1:
    return self[s.toNimSlice]
  result = newPyList[T]()
  for i in pyrange.range(s.start, s.stop, s.step):
    result.append self[i]



func reverse*(self: var PyList) = reverse(self.asSeq)

func pop*[T](self: var PyList[T]): T{.discardable.} = self.asSeq.pop()
func pop*[T](self: var PyList[T], index: int): T{.discardable.} =
  ## `index` can be negative to index backwards.
  let idx = if index < 0: self.len + index else: index
  result = self.asSeq[idx]
  self.asSeq.delete(idx)

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

func `+`*[T](self: PyList[T], x: openArray[T]): PyList[T] =
  list(self.asSeq & x)

func list*[T](x: sink seq[T]): PyList[T] = newPyList x
func list*[T](a: sink openArray[T]): PyList[T] = newPyList a
# Impl end

# the following does nothing with how PyList is implemented.

func list*[T](): PyList[T] =
  runnableExamples:
    assert len(list[int]()) == 0
  newPyList[T]()

func `*`*[T](n: Natural, ls: PyList[T]): PyList[T] =
  for _ in 1..n:
    result.extend ls

template `*`*[T](ls: PyList[T], n: Natural): PyList[T] =
  ls * n

func `*=`*[T](self: var PyList[T], n: int) =
  if n < 1: self.clear()
  self.extend self * (n-1)

template `+`*[T](self: var PyList[T], x: PyList[T]): PyList[T] =
  self.extend x

# it has side effects as it may call `items`
proc list*[T](iter: Iterable[T]): PyList[T] =
  when iter is Sized:
    result = newPyList[T](len(iter))
    for i, v in enumerate(iter):
      result[i] = v
  else:
    result = newPyList[T]()
    for i in iter:
      result.append(i)

PyList.genDollarRepr '[', ']', linear=true

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
    temp.add SortItem[typeof(key(v)), typeof(v)](key: key(v), data: v)
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

proc sorted*[T, K](x: Sequence[T],
    key: proc (x: T): K, reverse=false): PyList[T] =
  result = newPyList[T](len(x))
  seqSortWithKeyImpl[T, K](result, x, reverse, same=false)

proc sorted*[T, K](x: not Sequence[T] and Iterable[T],
    key: proc (x: T): K, reverse=false): PyList[T] =
  result = newPyList[T]()
  iterSortWithKeyImpl[T, K](result, x, reverse)

genDelItem PyList
genGenericSetItem PyList, Sequence
