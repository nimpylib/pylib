# Nimpylib


# WARNING: This repository is mostly a PoC, for full py2nim transpiler see [py2nim](https://github.com/metacraft-labs/py2nim)
Nimpylib is a collection of python-like operators and functions. It can help you to translate your Python program to Nim.

Also there's simple ```class``` macro similar to Python class (but without inheritance)

Nimpylib heavily relies on Nim generics, converters, operator overloading, and even on concepts

Example: Python-like range and print procedures:
```nim
import pylib
include pylib/range  # It's neccessary to include range module separately
let data = range(0, -10, -2)
echo data # @[0, -2, -4, -6, -8]
for i in range(10):
  print(i, endl = " ")  # 0 1 2 3 4 5 6 7 8 9

print("Hello,", input("What is your name? "), endl="\n~~~\n")
```
