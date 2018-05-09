# NimPylib

- **This repository is mostly a PoC, for full py2nim transpiler see [py2nim](https://github.com/metacraft-labs/py2nim)**

Nimpylib is a collection of python-like operators and functions (syntax sugar).
It can help you to translate your Python program to Nim.

Also there's simple `class` macro similar to Python `class` (but without inheritance).

Nimpylib heavily relies on Nim generics, converters, operator overloading, and even on concepts.


# Use

```nim
>>> import pylib
>>> include pylib/range  # It's necessary to include range module separately
>>>
>>> let python_like_range = range(0, -10, -2)  #  Mimic Pythons range()
>>> print(python_like_range)                   #  Mimic Pythons print()
@[0, -2, -4, -6, -8]
>>>
>>> for i in range(10):
      print(i, endl=" ")
0 1 2 3 4 5 6 7 8 9
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
>>> discard str("This is a string.")  # string.
>>> discard int(42)                   # integer.
>>> discard int('9')                  # integer from char.
>>> discard float(1.0)                # float.
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
>>> print(loads("""{"key": "value"}"""))  #  Mimic Pythons json.loads(str)
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
>>> timeit(100):  #  Mimic Pythons timeit.timeit("code_to_benchmark", number=int)
      sleep(9)    # Repeats this code 100 times. Output is very informative.

2018-05-09T02:01:33-03:00 TimeIt: 100 Repetitions on 920 milliseconds, 853 microseconds, and 808 nanoseconds, CPU Time 0.00128.
>>>
>>> with_open("some_file.txt", 'r'):  # Mimics Pythons with open(file, mode='r') as file:
      while not end_of_file(file):    # File is automatically assigned to file variable.
        print(file.read_line())       # No need for " as file", just path and mode.

>>>
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

- [Check the Examples folder for more examples.](https://github.com/Yardanico/nimpylib/tree/master/examples)
[Have more Macros or Templates for Python-like syntax, send Pull Request.](https://github.com/Yardanico/nimpylib/pulls)


# Install

```
nimble install pylib
```

- Uninstall `nimble uninstall pylib`.


# Requisites

- [Nim](https://nim-lang.org)
- [Nimble](https://github.com/nim-lang/nimble#installation)
