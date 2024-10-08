
##[
  translated from https://github.com/scijs/nextafter/blob/master/nextafter.js

  And add respect to the sign of zero, e.g.

  nextafter(-0.0, 0.0) == 0.0
  nextafter(0.0, -0.0) == -0.0
]##

#[
The MIT License (MIT)

Copyright (c) 2013 Mikola Lysenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]#

import ./inWordUtilsMapper

wu_import fromWords from fromWords
wu_import toWords from toWords

from std/math import pow, classify, FloatClass

const
  UINT_MAX = high uint32

  # 2 ^ (1-BIAS-N_frac)
  dbl_SMALLEST_DENORM = cast[float64](1u64) ## pow(2.0, -1074) a.k.a.  2^(1 - 1023 - 52)
  flt_SMALLEST_DENORM = cast[float32](1u32) ## pow(2f,  -149)  a.k.a.  2^(1 - 127  - 23)

template SMALLEST_DENORM[T](t: typedesc[T]): T =
  when T is float64: dbl_SMALLEST_DENORM
  else: flt_SMALLEST_DENORM

func nextafter*[F](x, y: F): F =
  let
    xFc = classify x
    yFc = classify y
  if xFc == fcNan: return x
  if yFc == fcNan: return y
  let x0 = x == 0
  if x == y:
    if x0 and xFc != yFc:  ## x, y is +-0.0 and their signs differ
      return y
    return x
  if x0:
    if y < 0:
      return -F.SMALLEST_DENORM
    else:
      return F.SMALLEST_DENORM
  var (hi, lo) = toWords(x)
  if (y > x) == (x > 0):
    if(lo == UINT_MAX):
      hi += 1
      lo = 0
    else:
      lo += 1
  else:
    if(lo == 0):
      lo = UINT_MAX
      hi -= 1
    else:
      lo -= 1

  return fromWords(hi, lo)
