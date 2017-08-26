# Nimpylib

Nimpylib is a collection of python-like operators and functions. It can help you to translate your Python program to Nim. 

Also there's simple ```class``` macro similar to Python class (but without inheritance)

Nimpylib heavily relies on Nim generics, converters, operator overloading, and even on concepts

Example: Python-like range and print procedures:
```nim
import pylib
let data = range(0, -10, -2)
echo data # @[0, -2, -4, -6, -8]

for i in range(10):
  print(i, endl = " ")
```