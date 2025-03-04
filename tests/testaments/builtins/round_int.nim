discard """
  action: "run"
  targets: "c js"

  output: ""
"""
import pylib/builtins
import pylib/ops
import pylib/Lib/random

import std/unittest

import ../../utils

var self = 0
template assertEqual(_: typeof(self); a, b: auto) = check(a == b)

block test_round:
        # check round-half-even algorithm. For round to nearest ten;
        # rounding map is invariant under adding multiples of 20
        let test_dict = [0, 0, 0, 0, 0, 0,
                     10, 10, 10, 10, 10, 10, 10, 10, 10,
                     20, 20, 20, 20, 20]
        var
          got, expected: int
          expect, x: int

        for offset in range(-520, 520, 20):
            for k, v in test_dict.pairs():
                got = round(k+offset, -1)
                expected = v+offset
                self.assertEqual(got, expected)

        # larger second argument
        self.assertEqual(round(-150, -2), -200)
        self.assertEqual(round(-149, -2), -100)
        self.assertEqual(round(-51, -2), -100)
        self.assertEqual(round(-50, -2), 0)
        self.assertEqual(round(-49, -2), 0)
        self.assertEqual(round(-1, -2), 0)
        self.assertEqual(round(0, -2), 0)
        self.assertEqual(round(1, -2), 0)
        self.assertEqual(round(49, -2), 0)
        self.assertEqual(round(50, -2), 0)
        self.assertEqual(round(51, -2), 100)
        self.assertEqual(round(149, -2), 100)
        self.assertEqual(round(150, -2), 200)
        self.assertEqual(round(250, -2), 200)
        self.assertEqual(round(251, -2), 300)
        self.assertEqual(round(172500, -3), 172000)
        self.assertEqual(round(173500, -3), 174000)
        when intOver64b:
          self.assertEqual(round(31415926535, -1), 31415926540)
          self.assertEqual(round(31415926535, -2), 31415926500)
          self.assertEqual(round(31415926535, -3), 31415927000)
          self.assertEqual(round(31415926535, -4), 31415930000)
          self.assertEqual(round(31415926535, -5), 31415900000)
          self.assertEqual(round(31415926535, -6), 31416000000)
          self.assertEqual(round(31415926535, -7), 31420000000)
          self.assertEqual(round(31415926535, -8), 31400000000)
          self.assertEqual(round(31415926535, -9), 31000000000)
          self.assertEqual(round(31415926535, -10), 30000000000)
          self.assertEqual(round(31415926535, -11), 0)
          self.assertEqual(round(31415926535, -12), 0)
          self.assertEqual(round(31415926535, -999), 0)

        # should get correct results even for huge inputs
        #  10**11 > int32.high; 10**20 > int64.high
        when intOver64b:
          for k in range(10, 19):
            got = round(10**k + 324678, -3)
            expect = 10**k + 325000
            self.assertEqual(got, expect)

        # nonnegative second argument: round(x, n) should just return x
        for n in range(5):
            for i in range(100):
                x = random.randrange(-10000, 10000)
                got = round(x, n)
                self.assertEqual(got, x)

        when intOver64b:
          for huge_n in [2**31-1, 2**31, 
                # 2**63-1, 2**63, 2**100, 10**100
          ]:
            self.assertEqual(round(8979323, huge_n), 8979323)

        # omitted second argument
        for i in range(100):
            x = random.randrange(-10000, 10000)
            got = round(x)
            self.assertEqual(got, x)


        # bad second argument
        #bad_exponents = ("brian", 2.0, 0j)
        #for e in bad_exponents:
        #    self.assertRaises(TypeError, round, 3, e)
