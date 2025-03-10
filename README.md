# NimPylib

[![C Test](https://github.com/nimpylib/pylib/workflows/testC/badge.svg)](https://github.com/nimpylib/pylib/actions/workflows/testC.yml)
[![JS Test](https://github.com/nimpylib/pylib/workflows/testJs/badge.svg)](https://github.com/nimpylib/pylib/actions/workflows/testJs.yml)
[![Docs](https://github.com/nimpylib/pylib/workflows/docs/badge.svg)](https://github.com/nimpylib/pylib/actions/workflows/docs.yml)
![](https://img.shields.io/github/languages/code-size/nimpylib/pylib?style=flat)
[![Commits](https://img.shields.io/github/last-commit/nimpylib/pylib?style=flat)](https://github.com/nimpylib/pylib/commits/)
<!--![](https://img.shields.io/github/stars/nimpylib/pylib?style=flat "Star NimPylib on GitHub!")
[![Issues](https://img.shields.io/github/issues-raw/nimpylib/pylib?style=flat)](https://github.com/nimpylib/pylib/issues)
[![PRs](https://img.shields.io/github/issues-pr-raw/nimpylib/pylib?style=flat)](https://github.com/nimpylib/pylib/pulls)-->

> Write Python in Nim

Nimpylib is a collection of Python-like operators/functions and libraries as well as syntax sugars.


---

[Read Docs](https://nimpylib.github.io/pylib/)
|
[Lib Docs][]
|
[Wiki about History](https://github.com/nimpylib/pylib/wiki/History)
|
[Design Wiki](https://github.com/nimpylib/pylib/wiki/Design)

[Lib Docs]: https://nimpylib.github.io/pylib/Lib

## Why NimPyLib?
It helps you to:
- use much Python-like out-of-box API in Nim:
  - with no need of any Python dependency (neither dynamic library nor binary).
  - even handy for ones who don't use much Python but want more functions in Nim
- translate your Python program to Nim:
  - gaining a right-away speed boot of even 700x
  - no worry about binary distribution or packaging, just "compile once, distribute everywhere"
  - rid of many annoying runtime-errors (which are turned to compile-time error)
- gain a better view into different behaviors between Python and Nim:
  - `dynamically-typed` vs `statically-typed`
  - unconvertible syntax from Python to Nim, e.g.
    [`end` keyword](./doc/mustRewriteExtern/endKeyword.md),
    [`not in` syntax](./doc/mustRewriteExtern/not-in.md)

### Backends

Thanks to Nim supporting multiply backends, pylib currently officially supports
to compile to C and JavaScript [^JS]. C++ and ObjC backends are currently not tested.

[^JS]: Some of features (listed
 [here](./tests/skipJs.txt))
 and Libs (listed
 [here](./src/pylib/Lib/test/skipJs.txt))
is not available for JS backend yet.

## Demo

```nim
import pylib
from pylib/Lib/timeit import timeit
from pylib/Lib/time import sleep
from pylib/Lib/sys import nil  # like python's `import sys`
from pylib/Lib/platform import nil  # like python's `import platform`
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
  print(list(python_like_range)[1:-1]) # [-2, -4, -6]
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

def show_literals():
  ls = [1, 2]  # if outside `def`, `ls` will be an Nim's `array`,
  #   which is fixed size and "pass by value"
  ls_shallow = ls
  ls.append(3)
  assert len(ls_shallow) == 3

  s = {"Rachel", "Zack"}  # if outside `def`, `s` will be an Nim's `set`,
  #    which only supports small ordinal type as elements
  s.add("Zack")
  assert len(s) == 2

  d = {  # if outside `def`, `d` will be an Nim's `array[I, (K, V)]`,
    #   which even lacks `__getitem__` method
    'S': "kaneki ken"
  }

  assert d['S'].title() == "Kaneki Ken"  # if outside `def`,
  #   all double-quotation marked literals will be Nim's `string`,
  #     which is more like `bytearray`
  #   and single-quotation marked literals will be Nim's `char`,
  #     which repesents a single byte (ASCII character)

show_literals()


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

show_unpack()

if (a := 6) > 5:
  assert a == 6

print("a".center(9)) # "    a    "

print("" or "b") # "b"
print("a" or "b") # "a"

print(not "") # True

print("Hello,", input("What is your name? "), endl="\n~\n")

def show_divmod_and_unpack(integer_bytes):
  (kilo, bite) = divmod(integer_bytes, 1_024)
  (mega, kilo) = divmod(kilo, 1_024)
  (giga, mega) = divmod(mega, 1_024)
show_divmod_and_unpack(2_313_354_324)

def lambda_closure(arg):
  anno = lambda: "hello " + arg
  return anno()
assert lambda_closure("world") == "hello world"

print(sys.platform) # "linux"

print(platform.machine) # "x86_64"

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
def test_open():
  with open("some_file.txt", 'w') as file:
    _ = file.write("hello world!")

  with open("some_file.txt", 'r') as file:
    while True:
      s = file.readline()
      if s == "": break
      print(s)

test_open()

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

Check the [Examples folder](./examples/) for more examples.
Have more Macros or Templates for Python-like syntax, send [Pull Request](https://github.com/nimpylib/pylib/pulls).

## Installation

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


## Requisites

- [Nim](https://nim-lang.org)


## Supported features

- [x] F-Strings `f"foo {variable} bar {1 + 2} baz"`
- [x] `str` `bytes` `bytearray` `list` `dict` `set` `frozenset()` with their methods
- [x] Python-like variable unpacking
- [x] Math with Float and Int mixed like Python.
- [x] `lambda:`
- [x] `class` Python-like OOP with methods and DocStrings (without multi-inheritance)
- [x] `@classmethod` and `@staticmethod`
- [x] `with open(fn, [, ...]):` Read, write, append, and `read()`, `seek()`, `tell()`, etc.
- [x] `super(...).method(...)`
- [x] `global/nonlocal` (with some limits)
- [x] `True` / `False`
- [x] `pass`
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
- [x] `long()` Python2 like (deprecated)
- [x] `u"string here"` / `u'a'` Python2 like
- [x] `b"string here"` / `b'a'`
- [x] `zip(*iterables, strict=False)`
- [x] (WIP) standard libraries `math`, `random`, `datetime`, `os`, `tempfile`, `timeit`, ... (see [Lib Docs][] for all supported)
- [ ] `aiter` `anext` and `await` (yet `async def` is supported)
- More...

### Features cannot be implemented
However, due to Nim's AST astrict[^nimInvalidAST], a few syntaxes of Python cannot be implemented.

See [here](./doc/mustRewriteExtern/) for details and workaround.

[^nimInvalidAst]: Mostly because they cannot form valid AST in Nim.

## Other Python-like modules

- [serach in nimble](https://nimble.directory/search?query=python)
- [metacraft-labs/py2nim](https://github.com/metacraft-labs/py2nim): py2nim transpiler in Nim.
- [py2many/py2many](https://github.com/py2many/py2many): py2nim transpiler in Python.
- [juancarlospaco/cpython](https://github.com/juancarlospaco/cpython): invoke Python Standard Library API in Nim.
- [yglukhov/nimpy](https://github.com/yglukhov/nimpy): Python bridge in Nim.

## Tests

This is one snippest from version 0.9.5:

> as too much tests output is it,
and it's not suitable to list too much content in README,
the following demo
is not likely to be updated from then on.

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

[Suite] gamma
  [OK] gamma(-integer)

[Suite] ldexp

[Suite] sumprod
  [OK] array
  [OK] CPython:test_math.testSumProd

[Suite] constants
  [OK] nan
  [OK] inf

[Suite] classify
  [OK] isinf
  [OK] isfinite

[Suite] nextafter_ulp
  [OK] nextafter
  [OK] ulp

[Suite] ldexp
  [OK] static
  [OK] small
  [OK] non-normal first arg
  [OK] large second arg

[Suite] ErrnoAttributeTests
  [OK] using_errorcode
[OK] touch, unlink, is_file
[OK] Lib/tempfile
[OK] Lib/time
[OK] Lib/timeit

[Suite] Lib/array
  [OK] py3.13: 'w' Py_UCS4
  [OK] bytes
  [OK] cmp
  [OK] byteswap

[Suite] os.path
  [OK] if export right
  [OK] getxtime

[Suite] Lib/os with no JS support
  [OK] mkdir rmdir
  [OK] open fdopen close
  [OK] get,set_inheritable
[OK] getattr/set/has
[OK] bytearray

[Suite] bytes
  [OK] getitem
  [OK] meth
  [OK] repr

[Suite] complex.__init__(str)
  [OK] from str
  [OK] negative_nans_from_string

[Suite] complex
  [OK] init
  [OK] literals
  [OK] str
  [OK] op

[Suite] complex.__repr__
  [OK] (N+nanj)
  [OK] real == 0.0

[Suite] complex.__pow__
  [OK] CPython:test_complex.ComplexTest.test_pow
  [OK] with small integer exponents
[OK] decorator
[OK] custom decorator
[OK] dict

[Suite] float.fromhex
  [OK] literals
  [OK] nans
  [OK] some values
  [OK] overflow
  [OK] zeros and underflow
  [OK] round-half-even

[Suite] float.fromhex and hex
  [OK] roundtrip

[Suite] float
  [OK] hex
  [OK] test_nan_signs
  [OK] is_integer
  [OK] as_integer_ratio

[Suite] rewrite as py stmt
  [OK] rewrite in `def`
  [OK] rewrite raise
[OK] Floor division
[OK] int.{from,to}_bytes
[OK] io & with
[OK] bltin iters
[OK] iters as iterable
[OK] iter/next
[OK] random
[OK] Lib/string
[OK] list shallow
[OK] list.sort
[OK] list methods
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
[OK] Modulo operations
[OK] int(x[, base])
[OK] float(str)
[OK] Range-like Nim procedure
[OK] str.format
[OK] str operations
[OK] str index
[OK] str methods
[OK] str.maketrans&translate
[OK] tonim macro
[OK] unpack macro
[OK] With statement
[OK] generics in func signature
[OK] generics in class's methods
[OK] set
PASS: tests/testaments/builtins/print.nim c                        ( 1.93 sec)
SKIP: tests/testaments/builtins/print.nim js
PASS: tests/testaments/builtins/print_ct.nim c                     ( 1.93 sec)
PASS: tests/testaments/builtins/zip_no_seq.nim c                   ( 1.96 sec)
PASS: tests/testaments/builtins/zip_more_args.nim c                ( 0.65 sec)
PASS: tests/testaments/builtins/filter_toseq_deadloop.nim c        ( 0.66 sec)
Used D:\software\scoop\shims\nim.exe to run the tests. Use --nim to override.
PASS: tests/testaments/pysugar/colonToSlice.nim c                  ( 2.75 sec)
SKIP: tests/testaments/pysugar/colonToSlice.nim js
PASS: tests/testaments/pysugar/strlitCat.nim c                     ( 1.92 sec)
SKIP: tests/testaments/pysugar/strlitCat.nim js
PASS: tests/testaments/pysugar/tripleStrTranslate.nim c            ( 0.84 sec)
PASS: tests/testaments/pysugar/autoSetListDict.nim c               ( 3.40 sec)
```
