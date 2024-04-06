
# v0.6.0 - 2024-03-09 

> the first release since forked from Yardanico's repo.

## Fixes for inconsistence with Python
### ascii
 
- for Unicode: use `\uhhhh` or `\UHHHHHHHH` instead of \uddd..
- use one of single/double quotation marks when another is in the string
- ...

### range
rename xrange back to range.

### filter
fix to make it a non-reentrant iterable, just like in Python.

### str method
- adjust `s.split()` to Python's (treat all unicode whitespace as sep).
- fix `capwords` to support unicode.
- add `capitalize`.
- fix `center` where `width` shall mean the total minimum width, instead of half.

## Feature additions

### def & async def
- add support for `def` outside `toNim` macro.
- support `async def`.


## Patches for Nim-compatibility

### print.nim
solve `warning[CStringConv]`.

### bin
add patches for `bin` to compile:

- add patch for JS `abs` of BigInt (as `bin` invokes abs), as js in nimv2 uses BigInt for int64

