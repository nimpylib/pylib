# NimPylib

[![Build status](https://github.com/litlighilit/nimpylib/workflows/Build/badge.svg)](https://github.com/litlighilit/nimpylib/actions)
![](https://img.shields.io/github/languages/top/litlighilit/nimpylib?style=flat)
![](https://img.shields.io/github/stars/litlighilit/nimpylib?style=flat "Star NimPylib on GitHub!")
![](https://img.shields.io/github/languages/code-size/litlighilit/nimpylib?style=flat)
[![Issues](https://img.shields.io/github/issues-raw/litlighilit/nimpylib?style=flat)](https://github.com/litlighilit/nimpylib/issues)
[![PRs](https://img.shields.io/github/issues-pr-raw/litlighilit/nimpylib?style=flat)](https://github.com/litlighilit/nimpylib/pulls)
[![Commits](https://img.shields.io/github/last-commit/litlighilit/nimpylib?style=flat)](https://github.com/litlighilit/nimpylib/commits/)

> Originating from a fork of https://github.com/Yardanico/nimpylib, which is announced to be not maintained since 2021. This is no longer a simple fork with some simple improvement, but with great features.

Nimpylib is a collection of Python-like operators/functions and libraries (<del>syntax sugar</del> no longer just syntax sugar).
It can help you to translate your Python program to Nim,
and gain a better view into different behaviors between Python and Nim.

# Usage

```nim
import pylib
from std/os import sleep  # python's `sleep` is in `time` module, however
from pylib/Lib/sys import nil  # like python's `import sys`
from pylib/Lib/platform import nil  # like python's `import sys`
import pylib/Lib/tempfile # more python-stdlib in pylib/Lib...

print 42  # print can be used with and without parenthesis too, like Python2.
pass str("This is a string.") # discard the string. Python doesn't allow this, however

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

timeit(100):  # Python-like timeit.timeit("code_to_benchmark", number=int)
  sleep(9)    # Repeats this code 100 times. Output is very informative.

# 2020-06-17T21:59:09+03:00 TimeIt: 100 Repetitions on 927 milliseconds, 704 microseconds, and 816 nanoseconds, CPU Time 0.0007382400000000003.

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
```

Nimpylib heavily relies on Nim generics, converters, operator overloading, and even on concepts.

Check the [Examples folder](https://github.com/litlighilit/nimpylib/tree/master/examples) for more examples.
Have more Macros or Templates for Python-like syntax, send [Pull Request](https://github.com/litlighilit/nimpylib/pulls).

# Installation

To install nimpylib, you can simply run
```shell
nimble install https://github.com/litlighilit/nimpylib
```
or
```shell
git clone https://github.com/litlighilit/nimpylib
cd nimpylib
nimble install
```

Uninstall with `nimble uninstall pylib`.


# Requisites

- [Nim](https://nim-lang.org)


# Supported features

- [x] F-Strings `f"foo {variable} bar {1 + 2} baz"`
- [x] `str` `list` `dict` `set` with their methods
- [x] Python-like variable unpacking
- [x] Math with Float and Int mixed like Python.
- [x] `import antigravity`
- [x] `lambda:`
- [x] `class` Python-like OOP with methods and DocStrings (without multi-inheritance)
- [x] `@classmethod` and `@staticmethod`
- [x] `with open(fn, [, ...]):` Read, write, append, and `read()`, `seek()`, `tell()`, etc.
- [x] `super(...).method(...)`
- [x] `global/nonlocal` (with some limits)
- [x] `with tempfile.TemporaryDirectory():` Read, write, append, and `file.read()`.
- [x] `with tempfile.NamedTemporaryFile() as file:` Read, write, append, and `file.read()`.
- [x] `timeit()` with Nanoseconds precision
- [x] `True` / `False`
- [x] `pass` also can take and discard any arguments
- [x] `del foo[x]`
- [x] `:=` Walrus Operator
- [x] `abs()`
- [x] `all()`
- [x] `any()`
- [x] `ascii()`
- [x] `bin()`
- [x] `chr()`
- [x] `complex()`
- [x] `divmod()`
- [x] `enumerate()`
- [x] `filter()`
- [x] `float()`
- [x] `format()`
- [x] `getattr()`
- [x] `hasattr()`
- [x] `hash()`
- [x] `hex()`
- [x] `id()`
- [x] `input()`
- [x] `int()`
- [x] `isinstance()`
- [x] `issubclass()`
- [x] `iter()`
- [x] `list()`
- [x] `map()`
- [x] `max()`
- [x] `min()`
- [x] `next()`
- [x] `oct()`
- [x] `ord()`
- [x] `open()` (though without close_fd, opener, errors)
- [x] `pow(base, exp, mod=None)`
- [x] `print("foo")` / `print "foo"` Python2 like
- [x] `range()`
- [x] `reversed(iterable)`
- [x] `round()`
- [x] `hasattr()`
- [x] `set()`, also named `pyset()` to distingish with `system.set`
- [x] `slice()`
- [x] `sorted(iterable)`
- [x] `str()`
- [x] `sum()`
- [x] `!=` and Python1 `<>`
- [x] `long()` Python2 like
- [x] `unicode()` Python2 like
- [x] `u"string here"` / `u'a'` Python2 like
- [x] `b"string here"` / `b'a'` Python2 like
- [x] `zip(iterable1, iterable2)`
- More...


### Other Python-like modules

- https://nimble.directory/search?query=python
- [Full py2nim transpiler](https://github.com/metacraft-labs/py2nim)
- [Python Standard Library for Nim that calls your Python executable](https://github.com/juancarlospaco/cpython)

### Tests

```console
$ nimble test
[OK] Range-like Nim procedure
[OK] Floor division
[OK] tonim macro
[OK] String operations
[OK] Modulo operations
[OK] unpack macro
[OK] Python-like types
[OK] divmod
[OK] pass
[OK] lambda
[OK] walrus operator
2024-03-28T22:39:46+08:00 TimeIt: 9 Repetitions on 0 nanoseconds, CPU Time 0.0.
[OK] timeit
[OK] hex()
[OK] chr()
[OK] oct()
[OK] ord()
[OK] bin()
[OK] filter()
[OK] With statement
[OK] io & with
[OK] tempfile
[OK] random
```

<!-- too small to show now
#### Stats

![Star nimpylib on GitHub]( "Star NimPylib on GitHub!")
-->