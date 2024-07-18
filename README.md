# NimPylib

[![C Test](https://github.com/nimpylib/pylib/workflows/testC/badge.svg)](https://github.com/nimpylib/pylib/actions/workflows/testC.yml)
[![JS Test](https://github.com/nimpylib/pylib/workflows/testJs/badge.svg)](https://github.com/nimpylib/pylib/actions/workflows/testJs.yml)
[![Docs](https://github.com/nimpylib/pylib/workflows/docs/badge.svg)](https://github.com/nimpylib/pylib/actions/workflows/docs.yml)
![](https://img.shields.io/github/languages/code-size/litlighilit/nimpylib?style=flat)
[![Commits](https://img.shields.io/github/last-commit/litlighilit/nimpylib?style=flat)](https://github.com/nimpylib/pylib/commits/)
<!--![](https://img.shields.io/github/stars/litlighilit/nimpylib?style=flat "Star NimPylib on GitHub!")
[![Issues](https://img.shields.io/github/issues-raw/litlighilit/nimpylib?style=flat)](https://github.com/nimpylib/pylib/issues)
[![PRs](https://img.shields.io/github/issues-pr-raw/litlighilit/nimpylib?style=flat)](https://github.com/nimpylib/pylib/pulls)-->

> Write Python in Nim

Nimpylib is a collection of Python-like operators/functions and libraries as well as syntax sugars.
It can help you to translate your Python program to Nim,
and gain a better view into different behaviors between Python and Nim.

---

[Read Docs](https://nimpylib.github.io/pylib/)
|
[Lib Docs](https://nimpylib.github.io/pylib/Lib)
|
[Wiki about History](https://github.com/nimpylib/pylib/wiki/History)

## Backends

Thanks to Nim supporting multiply backends, pylib currently officially supports
to compile to C and JavaScript [^JS]. C++ and ObjC backends are currently not tested.

[^JS]: Some of features (listed
 [here](https://github.com/nimpylib/pylib/blob/master/tests/skipJs.txt))
 and Libs (listed
 [here](https://github.com/nimpylib/pylib/blob/master/src/pylib/Lib/test/skipJs.txt))
is not available for JS backend yet.

# Usage

```nim
import pylib
from pylib/Lib/timeit import timeit
from pylib/Lib/time import sleep
from pylib/Lib/sys import nil  # like python's `import sys`
from pylib/Lib/platform import nil  # like python's `import sys`
import pylib/Lib/tempfile
# like python's `import tempfile; from tempfile import *`
# more python-stdlib in pylib/Lib/...

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
```

Nimpylib heavily relies on Nim generics, converters, operator overloading, and even on concepts.

Check the [Examples folder](https://github.com/nimpylib/pylib/tree/master/examples) for more examples.
Have more Macros or Templates for Python-like syntax, send [Pull Request](https://github.com/nimpylib/pylib/pulls).

# Installation

```shell
nimble install pylib
```

> If the installing is stuck with: 
`Downloading https://github.com/Yardanico/nimpylib using git`
Please note your nimble package.json is outdated, and that old URL is 404 now [^oldUrl].
Run `nimble refresh` to fetch a newer `package.json`

Of course, a workaround is to install with full URL:

```shell
nimble install https://github.com/nimpylib/pylib
```

[^oldUrl]: see [wiki-history](https://github.com/nimpylib/pylib/wiki/History#the-newer-package-url) for details

Uninstall with `nimble uninstall pylib`.


# Requisites

- [Nim](https://nim-lang.org)


# Supported features

- [x] F-Strings `f"foo {variable} bar {1 + 2} baz"`
- [x] `str` `bytes` `bytearray` `list` `dict` `set` `frozenset()` with their methods
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
- [x] `b"string here"` / `b'a'`
- [x] `zip(iterable1, iterable2)`
- More...


### Other Python-like modules

- [serach in nimble](https://nimble.directory/search?query=python)
- [metacraft-labs/py2nim](https://github.com/metacraft-labs/py2nim): py2nim transpiler in Nim.
- [py2many/py2many](https://github.com/py2many/py2many): py2nim transpiler in Python.
- [juancarlospaco/cpython](https://github.com/juancarlospaco/cpython): invoke Python Standard Library API in Nim.
- [yglukhov/nimpy](https://github.com/yglukhov/nimpy): Python bridge in Nim.

### Tests

```console
$ nimble test
[Suite] datetime
  [OK] utcoffset
  [OK] attrs
  [OK] isoformat

[Suite] fromisoformat
  [OK] if reversible

[Suite] timedelta
  [OK] init
  [OK] float init
  [OK] normalize
  [OK] stringify

[Suite] date
  [OK] fromisocalendar
  [OK] fromisocalendar_value_errors
  [OK] ordinal_conversion
  [OK] replace
  [OK] strftime
  [OK] ctime

[Suite] tzinfo
  [OK] fromtimestamp
[OK] Lib/os
[OK] os.path
[OK] Lib/time
[OK] Lib/timeit
[OK] bytes
[OK] bytes meth
[OK] str operations
[OK] str index
[OK] str methods
[OK] str.replace
[OK] PyStr.maketrans&translate
[OK] dict
[OK] random
[OK] Lib/string
[OK] Lib/math
[OK] Lib/tempfile
[OK] Python-like types
[OK] divmod
[OK] pass
[OK] lambda
[OK] walrus operator
[OK] hex()
[OK] chr()
[OK] oct()
[OK] ord()
[OK] bin()
[OK] bytearray
[OK] complex
[OK] decorator
[OK] custom decorator
[OK] rewrite in `def`
[OK] Floor division
[OK] io & with
[OK] iter/next
[OK] bltin iters
[OK] iters as iterable
[OK] list shallow
[OK] list.sort
[OK] list methods
[OK] Range-like Nim procedure
[OK] set
[OK] str.format
[OK] tonim macro
[OK] unpack macro
[OK] With statement
[OK] getattr/set/has
[OK] Modulo operations
[OK] int(x[, base])
[OK] float(str)
[OK] int.{from,to}_bytes
```
