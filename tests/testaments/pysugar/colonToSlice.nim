discard """
    output: '''
[2]
[1, 3, 4, 34]
4
'''
"""
import pylib

def f():
  ls = list([1, 2, 34])
  print(ls[1:2])
  ls[1:2] = [3, 4]
  print(ls)
  print(ls[2])
f()

