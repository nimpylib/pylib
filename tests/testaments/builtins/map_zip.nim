discard """
  output: '''
1 4
5
2 5
7
1
2
3
(1, 4, 'a')
(2, 5, 'b')
'''
"""
import pylib/builtins/iters

let
  it1 = [1, 2, 3]
  it2 = [4, 5]

func f(a, b: int): int =
  debugEcho a, ' ', b
  a+b

for i in map(f, it1, it2): echo i



func f(a: int): int = a
for i in map(f, it1): echo i

for i in zip(it1, it2, "abc"): echo i
