discard """
  output: '''
(1, 4)
(2, 5)
(3, 6)

(1, 4)
(2, 5)
(3, 6)

'''
"""
import pylib

template test(a, b) =
  for i in zip(a, b):
    echo i
  echo ""  # newline

test 1..3, 4..6
test range(1,4), range(4,7)

