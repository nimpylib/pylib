discard """
  output: '''
abccd
1234abccd5\n
false
'''
"""
import pylib

def f():
    s = f"abc" "cd"
    print(s)

    ss = "123" f"4{s}5" fr"\n"
    print(ss)

f()

echo compiles("sada" "asdsa")  # outside `def`
