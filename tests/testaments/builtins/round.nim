discard """
  action: "run"
  targets: "c"

  output: ""
"""
# TODO: targets add js, track https://github.com/nim-lang/Nim/issues/24696
# TODO: impl round(int[, n])
import pylib/builtins/round

# Lib/test/test_float.py

block:  # class RoundTestCase
  var self = 0
  template assertEqual(_, a, b) =
    if a == b: discard
    else:
      echo $a & " != " & $b
  self.assertEqual(round.round(6.5), 6)

  block: # def test_large_n(self):
        self.assertEqual(round(1e150, 300), 1e150)


  block: # def test_previous_round_bugs(self):
        # TODO: XXX: why round(562949953421312.5, 1) -> 56294995342131.51
        #[ 
        self.assertEqual(,
                          562949953421312.5)
        ]#
        self.assertEqual(round(56294995342131.5, 3),
                         56294995342131.5)

        # round-half-even
        self.assertEqual(round(25.0, -1), 20.0)
        self.assertEqual(round(35.0, -1), 40.0)
        self.assertEqual(round(45.0, -1), 40.0)
        self.assertEqual(round(55.0, -1), 60.0)
        self.assertEqual(round(65.0, -1), 60.0)
        self.assertEqual(round(75.0, -1), 80.0)
        self.assertEqual(round(85.0, -1), 80.0)
        self.assertEqual(round(95.0, -1), 100.0)
