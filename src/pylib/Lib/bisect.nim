
import ./n_bisect
import std/sequtils
import ../noneType

import ./collections/abc

template genbi(name){.dirty.} =
  proc name*[T; K](a: Sequence[T], x: K, lo=0, hi=len(a),
      key: NoneType|Key[T, K] = None): int =
    template oa: openArray{.dirty.} =
      when compiles(a.toOpenArray(lo, hi)):
        let
          lo = 0
          hi = len(a)
        a.toOpenArray(lo, hi)
      elif compiles(@a):
        @a
      elif compiles(a.toSeq):
        a.toSeq
      else:
        {.error: "not impl".}
    when key is NoneType:
      n_bisect.name(oa, x, lo, hi)
    else:
      n_bisect.name(oa, x, lo, hi, key)

genbi bisect_left
genbi bisect_right
genbi bisect

export insort, insort_left, insort_right

template genin(name, bi){.dirty.} =
  proc name*[T; K](a: MutableSequence[T], x: K, lo=0, hi=len(a),
      key: NoneType|Key[T, K] = None) =
    let lohi = bi(a, x, lo, hi)
    a.insert(lohi, x)

genin insort_left, bisect_left
genin insort_right, bisect_right
genin insort, bisect


