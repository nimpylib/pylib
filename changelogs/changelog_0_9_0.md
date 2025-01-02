
# v0.9.0 - 2024-5-12


## Fixes for inconsistence with Python

- builtins that shall return `str` now returns `PyStr` over `string`
- move `string` to the Py-stdlib (`pylib/Lib/string`).
- `f"xxx"` is now not `fr"xxx"` (it used to be).
- `list` is equipped with methods.
- `list`/`set` is now of shallow-copy.
- `str` is now unicode-based.
- `int`*`str` now works.
- `repr(str)` fits Python's behavior.
- stringification for `False`/`True` now returns `False`/`True` over `false`/`true`
- `open()` now returns either a FileIO or a TextIOWrapper
based on `PyStr` or `PyBytes`, instead of `string`
- constants in `os` is of `str`, instead of `string`
- `io` is moved to `Lib/`

## Feature additions

- support in-place op like `%=`
- support bit shift
- support `bytes` with its methods
- support `dict` and `set`
- support `complex`
- add `Lib/cmath`
- add `os.scandir`
- support `map`, `zip`
- support `getattr`, `setattr`, `hasattr`

### in `def` (func body)
- partly support `global/nonlocal` stmt
- partly support decorators
- support `raise ErrType[(msg)]
- support unpack-stmt (with restriction of no-omitting para.)

(see doc of pysugar/stmt/tonim.nim for details)

## Patches for Nim-compatibility
`Iterable` now longer causes `inner error` 
when JS for bracket literals on older Nim compiler.
(see [Nim #9550](https://github.com/nim-lang/Nim/issues/9550) for details)

