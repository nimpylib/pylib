## As Python's `MutableSequence` does not mixin these
##  we place them here.

import ./builtins/pyslice

import std/enumerate

template loopDown(a, b; step) =
  ## .. also reverse to avoid indices changing
  for i in countdown(min(len(ms)-1, a), max(0, b), step):
    ms.delitem(i)

template genDelItem*(Arr){.dirty.} =
  bind PySlice, toNimSlice, loopDown
  func delitem*(ms: var Arr, indices: Slice[int]) =
    loopDown indices.b, indices.a, 1

  func delitem*(ms: var Arr, indices: PySlice) =
    if indices.step == 1:
      ms.delitem(toNimSlice(indices))
      return
    let b = indices.stop - 1
    if indices.step < 0:
      loopDown(indices.start, b, indices.step)
    else:
      loopDown(b, indices.start, indices.step)


template bodySetItem*(Arr){.dirty.} =
  bind enumerate
  for i, idx in enumerate(indices.b .. indices.a):
    ms[idx] = o[i]

template genGenericSetItem*(Arr, Arr2){.dirty.} =
  bind bodySetItem
  func `[]=`*[T](ms: var Arr[T], indices: Slice[int], o: Arr2[T]) =
    bodySetItem Arr

template genNonGenericSetItem*(Arr, Arr2){.dirty.} =
  bind bodySetItem
  func `[]=`*(ms: var Arr, indices: Slice[int], o: Arr2) =
    bodySetItem Arr
