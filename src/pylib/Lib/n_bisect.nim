
import std/algorithm

type
  #Comparable = concept a, b
  #  cmp(a, b) is int
  Comparable = concept a, b
    a < b is bool
    a <= b is bool
    a == b is bool

  Key*[T; R: Comparable] = proc (x: T): R
  Cmp[T; R: SomeNumber] = proc (x, y: T): R

type RI = int
proc key_to_cmp[T, R](k: Key[T, R]): Cmp[T, RI] =
  proc (a, b: T): RI =
    if a == b: 0
    elif a > b: 1
    else: -1    

  
template genbi(name, nimName){.dirty.} =
  proc name*[T](a: openArray[T]; x: T; lo=0; hi=len(a)): int = nimName a[lo..<hi], x
  proc name*[T, K](a: openArray[T]; x: K; lo=0; hi=len(a); key: Key[T, K]): int =
    nimName a[lo..<hi], x, key_to_cmp key

genbi bisect, lowerBound
genbi bisect_right, lowerBound
genbi bisect_left, upperBound

template genin(name, bi){.dirty.} =
  proc name*[T](a: var seq[T]; x: T; lo=0, hi=len(a)) =
    let lohi = bi(a, x, lo, hi)
    a.insert(x, lohi)  ## xxx: the order is reversed from python's
  proc name*[T; K](a: var seq[T]; x: K; lo=0, hi=len(a), key: Key[T, K]) =
    let lohi = bi(a, key x, lo, hi, key=key)
    a.insert(x, lohi)  ## XXX: the order is reversed from Python's


genin insort_left, bisect_left
genin insort_right, bisect_right
genin insort, bisect



