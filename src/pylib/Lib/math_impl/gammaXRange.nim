
##[

.. hint:: CPython's uses MAX_GAMMA_X = 200.0 and MIN_GAMMA_X = -200.0,
  which differs the result above, but that's fine, as that's just a short-cut,
  there's still further check after that.
  See `pylib#38 comment<https://github.com/nimpylib/pylib/issues/38#issuecomment-2391828662>`_ for details.

Thus in fact, these constants are no need to be very accurate,
just to ensure they're greater than the actual value is enough.

But as such a short-cur is introduced, I think it better to make it accurate.

The values are calcuated from tools/math/gamma_x_range.py

## MAX_GAMMA_X
35.040096282958984'f32
0b01000010_00001100_00101001_00001111'f32

## MIN_GAMMA_X
-38.601410000000016'f32
0b11000010_00011010_01100111_11011000'f32

## MAX_GAMMA_X
171.6243769563027'f64
0b01000000_01100101_01110011_11111010_11100101_01100001_11110110_01000111'f64

## MIN_GAMMA_X
-177.7807064574756'f64
0b11000000_01100110_00111000_11111011_10001100_00011011_11010100_01000111'f64

## others

I found stdlib-js/gamma uses following values:
171.61447887182298
-170.5674972726612
But what I tested using SymPy was different.
If SymPy is right and my method is so,
then the old values are uncorrect and shall not be used,
 as the old checking range for zero/inf result is bigger.
 (it doesn't matter if that was smaller)
So I change to use current values.

]##

from ./constsUtils import genWithArg

genWithArg MAX_GAMMA_X, 35.04009704589844'f32,  171.6243769563027

genWithArg MIN_GAMMA_X, -38.601410000000016'f32, -177.7807064574756
