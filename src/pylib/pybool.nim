
from ./collections_abc import Iterable

type
  PyBool* = distinct bool

const
  True* = PyBool true ## True
  False* = PyBool false ## False

using self, opyb: PyBool
template genBin(op){.dirty.} =
  func op*(self; opyb): PyBool{.borrow.}
  func op*(self; b: bool): PyBool{.borrow.}
  func op*(b: bool, self): PyBool{.borrow.}
genBin `==`
func `is`*(self; opyb): PyBool{.borrow.}
func `xor`*(self; opyb): PyBool{.borrow.}  ## EXT
func `not`*(self): PyBool{.borrow.}
genBin `and`
genBin `or`

func repr*(self): string =
  ## Returns "True" or "False"
  if bool(self == True): "True"
  else: "False"

func `$`*(self): string =
  ## alias for `repr`_
  ## 
  ## NOTE: CPython's `bool`'s `__str__` is itself not defined,
  ## which is inherted from `object`,
  ## which will call `obj.__repr__` as fallback.
  ## This minics it.
  repr self

# https://github.com/nim-lang/Nim/issues/8197
#[
type
  HasLen = concept x
    x.len is int

  HasNotEqual = concept x
    x != 0 is bool

  HasMoreThan = concept x
    x > 0 is bool

  CanCompToNil = concept x
    x == nil is bool

converter bool*(arg: HasLen): bool = arg.len > 0
converter bool*(arg: HasNotEqual): bool = arg != 0
converter bool*(arg: HasMoreThan): bool = arg > 0 or arg < 0
converter bool*(arg: CanCompToNil): bool = arg != nil
]#

template toBool*[T](arg: T): bool =
  ## Converts argument to boolean, checking python-like truthiness.
  # If we have len proc for this object
  when compiles(arg.len):
    arg.len > 0
  elif T is SomeNumber:
  # If we can compare if it's not 0
    arg != 0  # works for NaN
  # If we can compare if it's greater than 0
  elif compiles(arg > 0):
    arg > 0 or arg < 0
  # Initialized variables only
  elif compiles(arg != nil):
    arg != nil
  else:
    # XXX: is this correct?
    true

converter toNimBool*(self): bool = bool(self)
converter pybool*(x: bool): PyBool = PyBool(x)
converter pybool*[T](x: T): PyBool =
  ## Converts any to `PyBool`
  ## 
  ## NOTE: In Nim, "implicit converter chain is not support".
  ## (See `manual.html<https://nim-lang.org/docs/manual.html#converters>`_).
  ## Therefore any type can be implicitly converted to `PyBool`, not `bool`,
  ## which, however, is desired, as if any is convertible to bool, 
  ## then there'll be ## compile-error for `repr(<list>)`
  PyBool toBool x

func `not`*[T](nself: T): PyBool = not nself.pybool
func `and`*[T](nself, npyb: T): T =
  if nself.pybool: npyb else: nself
func `or` *[T](nself, npyb: T): T =
  if nself.pybool: nself else: npyb

proc bool*[T](arg: T): PyBool = pybool(arg)  ## Alias for `pybool`_

func all*[T](iter: Iterable[T]): PyBool =
  ## Checks if all values in iterable are truthy
  result = true
  for element in iter:
    if not bool(element):
      return false

func any*[T](iter: Iterable[T]): PyBool =
  ## Checks if at least one value in iterable is truthy
  result = false
  for element in iter:
    if bool(element):
      return true
