# Nimpylib


# WARNING: This repository is mostly a PoC, for full py2nim transpiler see [py2nim](https://github.com/metacraft-labs/py2nim)

Nimpylib is a collection of python-like operators and functions (syntax sugar).
It can help you to translate your Python program to Nim.

Also there's simple ```class``` macro similar to Python class (but without inheritance).

Nimpylib heavily relies on Nim generics, converters, operator overloading, and even on concepts.


# Use

Example: Python-like `range`, `print`, `class`, `def` and more:

```nim
>>> import pylib
>>> include pylib/range  # It's necessary to include range module separately
>>>
>>> let data = range(0, -10, -2)
>>> echo data
@[0, -2, -4, -6, -8]
>>>
>>> for i in range(10):
      print(i, endl=" ")
0 1 2 3 4 5 6 7 8 9
>>>
>>> echo capwords("hello world capitalized")  # Like Pythons string.capwords()
Hello World Capitalized
>>> echo "a".center(9)
         a        
>>>
>>> print("Hello,", input("What is your name? "), endl="\n~~~\n")
>>>
>>> discard str("This is a string.")  # string.
>>> discard int(42)                   # integer.
>>> discard float(1.0)                # float.
>>>
>>> type Example = ref object
      start: int
      stop: int
      step: int

>>>
>>> class Example(object):
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


# Install

```
nimble install pylib
```

- Uninstall `nimble uninstall pylib`.


# Requisites

- [Nim](https://nim-lang.org)
- [Nimble](https://github.com/nim-lang/nimble#installation)
