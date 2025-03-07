
import pylib/builtins

import std/unittest

test "bltin iters":
  var t: seq[(int, char)]
  let res = list([(1,'a'), (2, 'b')])

  template chk(name, body) =
    checkpoint astToStr name
    block:
      body
    t.setLen 0  
  chk zip:
    for i in zip([1, 2], "ab"): t.add i
    check t == res
  chk "enumerate(x, start)":
    for i in enumerate("ab", start=1): t.add i
    check t == res

test "iters as iterable":
  # function that filters vowels
  proc fun(variable: char): bool =
    return variable in ['a', 'e', 'i', 'o', 'u']

  # sequence
  let sequence = ['g', 'e', 'e', 'j', 'k', 'i', 's', 'p', 'r', 'e', 'o']
  template genFiltered(): untyped = filter(fun, sequence)
  let filtered = genFiltered()
  let res = @['e', 'e', 'i', 'e', 'o']
  var data: seq[char]
  for s in filtered:
    data.add s

  check data == res

  let nFiltered = genFiltered()
  check list(nFiltered) == res

  let otherData = @[0, 1, 2, 3, 4, 5, 6, 7, 8, -1, 12412, 0, 31254, 0]

  let other = filter(None, otherData)

  check list(other) == @[1, 2, 3, 4, 5, 6, 7, 8, -1, 12412, 31254]


test "bltin iters":
  var t: seq[(int, char)]
  let res = list([(1,'a'), (2, 'b')])

  template chk(name, body) =
    checkpoint astToStr name
    block:
      body
    t.setLen 0  
  chk zip:
    for i in zip([1, 2], "ab"): t.add i
    check t == res
  chk "enumerate(x, start)":
    for i in enumerate("ab", start=1): t.add i
    check t == res

test "iters as iterable":
  # function that filters vowels
  proc fun(variable: char): bool =
    return variable in ['a', 'e', 'i', 'o', 'u']

  # sequence
  let sequence = ['g', 'e', 'e', 'j', 'k', 'i', 's', 'p', 'r', 'e', 'o']
  template genFiltered(): untyped = filter(fun, sequence)
  let filtered = genFiltered()
  let res = @['e', 'e', 'i', 'e', 'o']
  var data: seq[char]
  for s in filtered:
    data.add s

  check data == res

  let nFiltered = genFiltered()
  check list(nFiltered) == res

  let otherData = @[0, 1, 2, 3, 4, 5, 6, 7, 8, -1, 12412, 0, 31254, 0]

  let other = filter(None, otherData)

  check list(other) == @[1, 2, 3, 4, 5, 6, 7, 8, -1, 12412, 31254]

