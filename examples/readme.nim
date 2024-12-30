import pylib
from pylib/Lib/timeit import timeit
from pylib/Lib/time import sleep
from pylib/Lib/platform import nil  # like python's `import sys`
from pylib/Lib/sys import nil  # like python's `import platform`
import pylib/Lib/tempfile
# like python's `import tempfile; from tempfile import *`
# more python-stdlib in pylib/Lib/...

print 42  # print can be used with and without parenthesis too, like Python2.

# NOTE: from now on, the following is just valid Python3 code!
# only add the following to make it Python:
# import platform
# from timeit import timeit
# from time import sleep
# from tempfile import NamedTemporaryFile, TemporaryDirectory
print( f"{9.0} Hello {42} World {1 + 2}" ) # Python-like string interpolation

class O:
  @staticmethod
  def f():
    print("O.f")

O.f()

def show_range_list():
  python_like_range = range(0, -10, -2)
  print(list(python_like_range)) # [0, -2, -4, -6, -8]
show_range_list()

# Why using so many `def`s?
# as in `def`, you can write Nim more Python-like
# e.g. nondeclared assignment

# func definition
# typing is suppported and optional
def foo(a: int, b = 1, *args) -> int:
  def add(a, b): return a + b # nesting
  for i in args: print(i)
  return add(a, b)

# python 3.12's type statement
type Number = float | int  # which is originally supported by nim-lang itself, however ;) 

for i in range(10):
  # 0 1 2 3 4 5 6 7 8 9
  print(i, endl=" ")
print("done!")

# Python-like variable unpacking
def show_unpack():
  data = list(range(3, 15, 2))
  (first, second, *rest, last) = data
  assert (first + second + last) == (3 + 5 + 13)
  assert list(rest) == list([7, 9, 11])

show_unpack()

if (a := 6) > 5:
  assert a == 6

if (b := 42.0) > 5.0:
  assert b == 42.0

if (c := "hello") == "hello":
  assert c == "hello"

print("a".center(9)) # "    a    "

print("" or "b") # "b"
print("a" or "b") # "a"

print(not "") # True

print("Hello,", input("What is your name? "), endl="\n~\n")

def show_divmod_and_unpack(integer_bytes):
  (kilo, bite) = divmod(integer_bytes, 1_024)
  (mega, kilo) = divmod(kilo, 1_024)
  (giga, mega) = divmod(mega, 1_024)
  (tera, giga) = divmod(giga, 1_024)
  (peta, tera) = divmod(tera, 1_024)
  (exa, peta)  = divmod(peta, 1_024)
  (zetta, exa) = divmod(exa,  1_024)
  (yotta, zetta) = divmod(zetta, 1_024)
show_divmod_and_unpack(2_313_354_324)

let arg = "hello"
let anon = lambda: arg + " world"
assert anon() == "hello world"


print(sys.platform) # "linux"

print(platform.machine) # "amd64"

def allAny():
  truty = all([True, True, False])
  print(truty) # False

  truty = any([True, True, False])
  print(truty) # True
allAny()

def a_little_sleep():
  "sleep around 0.001 milsecs."
  # note Nim's os.sleep's unit is milsec,
  # while Python's time.sleep's is second.
  sleep(0.001)

assert timeit(a_little_sleep, number=1000) > 1.0

# Support for Python-like with statements
# All objects are closed at the end of the with statement
def t_open():
  with open("some_file.txt", 'w') as file:
    _ = file.write("hello world!")

  with open("some_file.txt", 'r') as file:
    while True:
      s = file.readline()
      if s == "": break
      print(s)

t_open()

def show_tempfile():
  with NamedTemporaryFile() as file:
    _ = file.write(b"test!")  # in binary mode

  with TemporaryDirectory() as name:
    print(name)

show_tempfile()

class Example(object):  # Mimic simple Python "classes".
  """Example class with Python-ish Nim syntax!."""
  start: int
  stop: int
  step: int
  def init(self, start, stop, step=1):
    self.start = start
    self.stop = stop
    self.step = step

  def stopit(self, argument):
    """Example function with Python-ish Nim syntax."""
    self.stop = argument
    return self.stop

# Oop, the following is no longer Python....
let e = newExample(5, 3)
print(e.stopit(5))
