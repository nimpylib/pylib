discard """
  action: "run"
  targets: "c js"

  output: ""
"""

import pylib/builtins # /[round, attr]


import pylib/builtins/[pyrange, complex, format]
import pylib/numTypes/floats

import pylib/Lib/[unittest, math, random, sys]

import ../../utils

when intOver64b:
  from pylib/ops import `**`

template withIfInt64(init, more): untyped =
  when intOver64b: @init & @more
  else: init

# Lib/test/test_float.py

proc assertFloatsAreIdentical(self: TestCase, x, y: float) =
  template `<->`(a, b: bool): bool = a == b
  self.assertTrue (x.isnan <-> y.isnan) or
      x == y and (x != 0.0 or copySign(1.0, x) == copySign(1.0, y))

#@support.requires_IEEE_754
#class RoundTestCase(unittest.TestCase, FloatsAreIdenticalMixin):
block:
    var self = newTestCase()
    #[
    block: #def test_inf_nan(self):
        self.assertRaises(OverflowError, round, INF)
        self.assertRaises(OverflowError, round, -INF)
        self.assertRaises(ValueError, round, NAN)
        self.assertRaises(TypeError, round, INF, 0.0)
        self.assertRaises(TypeError, round, -INF, 1.0)
        self.assertRaises(TypeError, round, NAN, "ceci n'est pas un integer")
        self.assertRaises(TypeError, round, -0.0, complex(0, 1))
]#
    block: #def test_inf_nan_ndigits(self):
        self.assertEqual(round(INF, 0), INF)
        self.assertEqual(round(-INF, 0), -INF)
        self.assertTrue(math.isnan(round(NAN, 0)))

    block: #def test_large_n(self):
        for n in withIfInt64([324, 325, 400], [2**31-1, 2**31, 2**32, #[2**100]# ]):
            self.assertEqual(round(123.456, n), 123.456)
            self.assertEqual(round(-123.456, n), -123.456)
            self.assertEqual(round(1e300, n), 1e300)
            self.assertEqual(round(1e-320, n), 1e-320)
        self.assertEqual(round(1e150, 300), 1e150)
        self.assertEqual(round(1e300, 307), 1e300)
        self.assertEqual(round(-3.1415, 308), -3.1415)
        self.assertEqual(round(1e150, 309), 1e150)
        self.assertEqual(round(1.4e-315, 315), 1e-315)

    block: #def test_small_n(self):
        for n in withIfInt64([-308, -309, -400], [1-2**31, -2**31, -2**31-1, #[-2**100]# ]):
            self.assertFloatsAreIdentical(round(123.456, n), 0.0)
            self.assertFloatsAreIdentical(round(-123.456, n), -0.0)
            self.assertFloatsAreIdentical(round(1e300, n), 0.0)
            self.assertFloatsAreIdentical(round(1e-320, n), 0.0)

#[
    block: #def test_overflow(self):
        self.assertRaises(OverflowError, round, 1.6e308, -308)
        self.assertRaises(OverflowError, round, -1.7e308, -308)
]#
    unittest.skipUnless(getattr(sys, "float_repr_style", "") == "short",
                         "applies only when using short float repr style"):
    # def test_previous_round_bugs(self):
        self.assertEqual(round(562949953421312.5, 1),
                          562949953421312.5)
    
        self.assertEqual(round(56294995342131.5, 3),
                         56294995342131.5)

    block:
        # round-half-even
        self.assertEqual(round(25.0, -1), 20.0)
        self.assertEqual(round(35.0, -1), 40.0)
        self.assertEqual(round(45.0, -1), 40.0)
        self.assertEqual(round(55.0, -1), 60.0)
        self.assertEqual(round(65.0, -1), 60.0)
        self.assertEqual(round(75.0, -1), 80.0)
        self.assertEqual(round(85.0, -1), 80.0)
        self.assertEqual(round(95.0, -1), 100.0)



    unittest.skipUnless(getattr(sys, "float_repr_style", "") == "short",
                         "applies only when using short float repr style"):
    #def test_matches_float_format(self):
        # round should give the same results as float formatting
        proc chk(x: float) =
            self.assertEqual(float(format(x, ".0f")), round(x, 0))
            self.assertEqual(float(format(x, ".1f")), round(x, 1))
            self.assertEqual(float(format(x, ".2f")), round(x, 2))
            self.assertEqual(float(format(x, ".3f")), round(x, 3))
        for i in range(500):
            chk(i/1000)

        for i in range(5, 5000, 10):
            chk(i/1000)

        for i in range(500):
            chk(random.random())
