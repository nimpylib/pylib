## As Python's `MutableSequence` does not mixin these
##  we place them here.

import ./builtins/pyslice

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

template moveItems(ms, dest, frm, n) =
  ## .. also reverse to avoid indices changing
  when declared(moveMem):
    when compiles(addr ms[dest]):
      moveMem(addr ms[dest], addr ms[frm], n*sizeof(ms[0]))
    else:
      moveMem(ms.getPtr dest, ms.getPtr frm, n*sizeof(ms[0]))
  else:
    if frm > dest:
      for i in 0..<n:
        ms[dest+i] = ms[frm+i]
    else:
      for i in countdown(n-1, 0):
        ms[dest+i] = ms[frm+i]

template bodySetItem*(Arr){.dirty.} =
  bind moveItems
  var ilow = indices.a
  let ihigh = indices.b + 1
  let norig = ihigh - ilow
  assert norig >= 0
  let n = o.len
  let d = n - norig
  let le = ms.len
  if le + d == 0:
    ms.clear()
    return
  if d < 0:  # Delete -d items
    moveItems(ms, ihigh+d, ihigh, le-ihigh)
    ms.setLen le+d
  elif d > 0:  # Insert d items
    ms.setLen le+d
    moveItems(ms, ihigh+d, ihigh, le-ihigh)
  for k in 0..<n:
    ms[ilow] = o[k]
    ilow.inc

template genGenericSetItem*(Arr, Arr2){.dirty.} =
  bind bodySetItem
  func `[]=`*[T](ms: var Arr[T], indices: Slice[int], o: Arr2[T]) =
    bodySetItem Arr

template genNonGenericSetItem*(Arr, Arr2){.dirty.} =
  bind bodySetItem
  func `[]=`*(ms: var Arr, indices: Slice[int], o: Arr2) =
    bodySetItem Arr
