# NimPylib

![](https://raw.githubusercontent.com/Yardanico/nimpylib/master/carbon.png "Python-like Syntax for Nim")

![](https://img.shields.io/github/languages/top/Yardanico/nimpylib?style=for-the-badge)
![](https://img.shields.io/github/languages/count/Yardanico/nimpylib?logoColor=green&style=for-the-badge)
![](https://img.shields.io/github/stars/Yardanico/nimpylib?style=for-the-badge "Star NimPylib on GitHub!")
![](https://img.shields.io/maintenance/yes/2019?style=for-the-badge "2019")
![](https://img.shields.io/github/languages/code-size/Yardanico/nimpylib?style=for-the-badge)
![](https://img.shields.io/github/issues-raw/Yardanico/nimpylib?style=for-the-badge "Bugs")
![](https://img.shields.io/github/issues-pr-raw/Yardanico/nimpylib?style=for-the-badge "PRs")
![](https://img.shields.io/github/last-commit/Yardanico/nimpylib?style=for-the-badge "Commits")

Nimpylib is a collection of python-like operators and functions (syntax sugar).
It can help you to translate your Python program to Nim.


# Use

```python
>>> import pylib
>>> include pylib/range  # It's necessary to include range module separately
>>>
>>> from pylib/future import braces
>>> import pylib/antigravity
>>>
>>> print( f"{9.0} Hello {42} World {1 + 2}" ) #  Mimic Pythons F-String
>>> let python_like_range = range(0, -10, -2)  #  Mimic Pythons range()
>>> print(python_like_range)                   #  Mimic Pythons print()
@[0, -2, -4, -6, -8]
>>>
>>> for i in range(10):
      print(i, endl=" ")
0 1 2 3 4 5 6 7 8 9
>>>
>>> if ( "a".`:=` 6 ) > 5:
>>>   assert a == 6
>>>
>>> if ( "b".`:=` 42.0 ) > 5.0:
>>>   assert b == 42.0
>>>
>>> if ( "c".`:=` "hello" ) == "hello":
>>>   assert c == "hello"
>>>
>>> print(capwords("hello world capitalized"))  # Like Pythons string.capwords()
Hello World Capitalized
>>> print("a".center(9))       # Mimic Pythons str.center()
"         a         "
>>>
>>> print("abc123".isalnum())  #  Mimic Pythons str.isalnum()
true
>>> print("abc123#$%".isalnum())
false
>>>
>>> print("" or "b")   #  Mimic Pythons str or str
"b"
>>> print("a" or "b")
"a"
>>>
>>> print(not "")      #  Mimic Pythons not str
true
>>>
>>> print("Hello,", input("What is your name? "), endl="\n~\n")  #  Mimic Pythons input()
>>>
>>> pass str("This is a string.")  # string.
>>> pass int(42)                   # integer.
>>> pass int('9')                  # integer from char.
>>> pass float(1.0)                # float.
>>>
>>> let integer_bytes = int64(2313354324)
>>> (kilo, bite) = divmod(integer_bytes, int64(1_024))  # Mimic Python divmod()
>>> (mega, kilo) = divmod(kilo, int64(1_024))
>>> (giga, mega) = divmod(mega, int64(1_024))
>>> (tera, giga) = divmod(giga, int64(1_024))
>>> (peta, tera) = divmod(tera, int64(1_024))
>>> (exa, peta)  = divmod(peta, int64(1_024))
>>> (zetta, exa) = divmod(exa,  int64(1_024))
>>> (yotta, zetta) = divmod(zetta, int64(1_024))
>>>
>>> let arg = "hello"
>>> let anon = lambda: arg + " world"  # Mimic Pythons lambda
>>> assert anon() == "hello world"
>>>
>>> print(json_loads("""{"key": "value"}""")  #  Mimic Pythons json.loads(str)
{"key":"value"}
>>>
>>> print(sys.platform)              #  Mimic Pythons sys.*
"linux"
>>>
>>> print(platform.processor)        #  Mimic Pythons platform.*
"amd64"
>>>
>>> var truty: bool
>>> truty = all([True, True, False]) #  Mimic Pythons all(iterable)
>>> print(truty)
false
>>> truty = any([True, True, False]) #  Mimic Pythons any(iterable)
>>> print(truty)
true
>>>
>>> timeit(100):  # Mimic Pythons timeit.timeit("code_to_benchmark", number=int)
      sleep(9)    # Repeats this code 100 times. Output is very informative.

2018-05-09T02:01:33-03:00 TimeIt: 100 Repetitions on 920 milliseconds, 853 microseconds, and 808 nanoseconds, CPU Time 0.00128.
>>>
>>> with_open("some_file.txt", 'r'):  # Mimics Pythons with open(file, mode='r') as file:
      while not end_of_file(file):    # File is automatically assigned to file variable.
        print(file.read_line())       # No need for " as file", just path and mode.
                                      # File is closed automatically.

>>> with_NamedTemporaryFile():        # Mimics Pythons with tempfile.NamedTemporaryFile() as file:
      print(file.read())              # File is automatically assigned to file variable.
                                      # File is closed and deleted automatically.

>>> with_TemporaryDirectory():        # Mimics Pythons with tempfile.TemporaryDirectory():
      print(name)                     # Folder path is automatically assigned to name variable.
                                      # Folder is deleted automatically.

>>>
>>> type Example = ref object
      start: int
      stop: int
      step: int

>>>
>>> class Example(object):            #  Mimic Python Classes.
      """Example class with Python-ish Nim syntax!."""

      def init(self, start, stop, step=1):
        self.start = start
        self.stop = stop
        self.step = step

      def stopit(self, argument):
        """Example function with Python-ish Nim syntax."""
        self.stop = argument
        return self.stop

>>>
```

Also there's simple `class` macro similar to Python `class` (but without inheritance).

Nimpylib heavily relies on Nim generics, converters, operator overloading, and even on concepts.

- [Check the Examples folder for more examples.](https://github.com/Yardanico/nimpylib/tree/master/examples)
[Have more Macros or Templates for Python-like syntax, send Pull Request.](https://github.com/Yardanico/nimpylib/pulls)


# Install

```
nimble install pylib
```

- Uninstall `nimble uninstall pylib`. https://nimble.directory/pkg/pylib


# Requisites

- [Nim](https://nim-lang.org)


# Support

- ✅ F-Strings `f"foo {variable} bar {1 + 2} baz"` and string functions
- ✅ Python OOP class with methods and DocStrings
- ✅ Math with Float and Int mixed like Python.
- ✅ `import antigravity`
- ✅ `from __future__ import braces`
- ✅ `lambda:`
- ✅ `with open("file.ext", 'w'):` Read, write, append, and `file.read()`.
- ✅ `with tempfile.TemporaryDirectory():` Read, write, append, and `file.read()`.
- ✅ `with tempfile.NamedTemporaryFile() as file:` Read, write, append, and `file.read()`.
- ✅ `timeit()` with Nanoseconds precision
- ✅ `json.loads()` also can Pretty-Print
- ✅ `True` / `False`
- ✅ `__import__()` Named `import()`
- ✅ `pass` also can take and discard any arguments
- ✅ `:=` Walrus Operator, for numbers and strings
- ✅ `abs()`
- ✅ `all()`
- ✅ `any()`
- ✅ `bin()`
- ✅ `chr()`
- ✅ `divmod()`
- ✅ `enumerate()`
- ✅ `filter()`
- ✅ `float()`
- ✅ `hex()`
- ✅ `id()`
- ✅ `input()`
- ✅ `int()`
- ✅ `isinstance()`
- ✅ `issubclass()`
- ✅ `iter()`
- ✅ `list()`
- ✅ `map()`
- ✅ `max()`
- ✅ `min()`
- ✅ `oct()`
- ✅ `ord()`
- ✅ `print("foo")` / `print "foo"` Python2 like
- ✅ `range()`
- ✅ `str()`
- ✅ `sum()`
- ✅ `<>` Python1 and Python2 `!=`
- ✅ `long()` Python2 like
- ✅ `unicode()` Python2 like
- ✅ `ascii()` Python2 like
- ✅ `u"string here"` / `u'a'` Python2 like
- ✅ `b"string here"` / `b'a'` Python2 like
- More...


### Other Python-like modules

- https://nimble.directory/search?query=python
- [Full py2nim transpiler](https://github.com/metacraft-labs/py2nim)


### Tests

```console
$ nimble test
  [OK] Range-like Nim procedure
  [OK] Floor division
  [OK] Class macro
  [OK] tonim macro
  [OK] String operations
  [OK] Modulo operations
  [OK] Miscelaneous
```


#### Stats

![Star nimpylib on GitHub](https://starchart.cc/Yardanico/nimpylib.svg "Star NimPylib on GitHub!")


[  ⬆️  ⬆️  ⬆️  ⬆️  ](#NimPylib "Go to top")
