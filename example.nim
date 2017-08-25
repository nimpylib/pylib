# Almost direct translation of https://github.com/famzah/langs-performance/blob/master/primes.py
import pylib

proc get_primes7(n: int): seq[int] = 
  if n < 2:
    return @[]
  if n == 2:
    return @[2]
  var s = range(3, n + 1, 2)
  var mroot = n ** 0.5
  var half = len(s)
  var i = 0
  var m = 3
  while m <= mroot:
    if s[i]:
      var j = (m * m - 3) // 2
      s[j] = 0
      while j < half:
        s[j] = 0
        j += m
    i = i + 1
    m = 2 * i + 3
  result = @[2]
  for x in s:
    if x:
      result.add(x)

let res = get_primes7(10000000)
print("Found $1 prime numbers.".format(len(res)))