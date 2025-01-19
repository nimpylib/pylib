
discard """
  output: '''
-1
'''
"""

import pylib


def g():
    def f(x):
      return x
    
    print(f(x=-1))

    x = 3==-1
    assert not(5==-1)  ## NOTE: par is a must!
    ## or it'll be `not(5) == -1` in Nim
    assert not x

g()

