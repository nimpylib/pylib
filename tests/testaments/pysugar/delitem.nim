discard """
  output: '''
[4]
'''
"""
import pylib


def f():
    ls = [1, 2, 3]
    del ls[-1]

    ls.append(4)

    del ls[0:2]
    print(ls)

f()
