
import pylib

import std/unittest

test "list shallow":
  var ls = list([1,2,3])
  var ls1 = ls
  ls1[0] = 3
  check ls[0] == 3

test "list.sort":
  
  template chkSorted(x) =
    mixin cmp
    var pre = x[0]
    for i in 1..<len(x):
      if cmp(pre, x[i]) > 0: check false
      pre = x[i]
  var nums = list([1,2,4,6,0,3])
  nums.sort()
  chkSorted nums

  when not defined(js):  
    ## XXX: compile err when JS
    ##   about Iterable concept's item match
    type O = tuple
      nouse: float
      key: int
    func cmp(a, b: O): int = a.key - b.key
    var ls = list([
      (1.0, 10), (3.0, 8), (2.0, 9)
    ])
    ls.sort(key=proc (o: O): int = o.key)
    chkSorted(ls)


test "list methods":
  var ls = list([-1,2,3])
  ls.append(4)
  check len(ls) == 4

  ls.extend([1,2,3])
  del ls[0]
  check len(ls) == 6

  when not defined(js):
    block:
      checkpoint "to check slice as index"
      var ls = list([1,2,3,4])
      check ls[slice(2)] == [1, 2]
      ls[slice(0, 3, 2)] = [5,1]
      check ls == [5,2,1,4]

      expect ValueError:
        ls[slice(0, 3, 2)] = [1]
      expect ValueError:
        ls[slice(0, 2, 2)] = range(4)
      

