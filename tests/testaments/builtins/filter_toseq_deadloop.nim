discard """
  output: '''
@[1, 3]
'''
  timeout: 5
"""

# issue #3
import pylib/builtins/iters
import std/sequtils
echo filter(None, [1, 0, 3]).toSeq
