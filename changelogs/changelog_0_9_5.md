
# v0.9.5 - 2024-12-27

## Python Syntax
- generics def
- generics class
- raise from statement

## Fixes for inconsistence with Python
- Python3.13 dedent doc string

## Fixes
- print:
  - js cannot compile
  - nimvm for non-NL `endl` now err over do nothing

### Lib
- array:
  - iter cannot compile
  - tobytes loop index starting fault (caused RangeDefect)

## Feature additions
### Lib
- tempfile: `gettemp{dir,prefix}[b]`
- newly added:
  - inspect: (Signature,etc not impl yet)
  - errno

## Patches for Nim-compatibility
- supports Nim 2.3.1

## deprecate
- deprecate `newPyDictImpl` over `newPyDict`, to be removed since 0.10
