
# v0.8.0 - 2024-04-09

> the second release since forked from Yardanico's repo.

## Fixes for inconsistence with Python

### `%` and `//`
- fix `%` and `//` to behave `floorMod` and `floorDiv`,
see their doc for details
- `divmod`

### ord
when not `release`, 
raises `TypeError` if the string argument contains not only one character


### read of Text Stream

fix `textFile.read` to:

- respect different NewLine Mode.
- respect `encoding`.

## Feature additions

### def in class
#### full support about params
e.g.
```Python
# can compile as Nim via pylib
class C:
  def f(self, a: int): return a+1
  def g(self, a) -> int: return a+1
```
#### inheritance and `super`
e.g.
```Python
class A:
  def f(self): return "A"
class B(A):
  def f(self): return super().f()
```

### issubclass & isinstance

### id
returns address as int

### io
support `open` with more Python's params, e.g. `encoding` (though still not all)

add `seek` `tell`, and try to minic Python's 

> see comments on `io.nim` for details


### pow
`pow(base, exp, modulo)`

For example, `pow(1234, 20, 73)` results in `9` while `1234^20` is bigger than `high int`, where this function is useful.


### math
implement all function in Python 3.10 math

### tempfile

mktemp, mkdtemp,

NamedTemporaryFile, TemporaryDirectory


### random
use a inner state

### os

system, open, close, fdopen, ...

truncate, stat, ...

mkdir, rmdir, getcwd, setcwd

#### os.path
dirname, abspath, isabs, ...

## Patches for Nim-compatitability

> the following used to fail to run under nimv2

### pass
nimv2 somehow has a bug

```Nim
# lib.nim
template pass* = discard
template pass*(_) = discard

# main.nim
import lib
pass  # <- Error: ambiguous identifier: 'pass' -- ...
```
Then this version passes by this bug


### encodings

see [`fixes: #223481`](https://github.com/nim-lang/Nim/pull/23481)

