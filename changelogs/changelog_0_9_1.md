
# v 0.9.1 - 2024-06-21


## Fixes for inconsistence with Python

- sys.hexversion is now an int instead of a string
- functions in `Lib/os` now raise subclass of `OSError` when it shall
- str/bytes.isupper/islower is no longer `all(map(lambda c: c.islower(), s))`, but only checks alpha.
- `str.title()` now works for Ligatures.
- str.upper, str.lower now use full case mapping instead of simple mapping.
- `str.casefold()` no longer just `toLower()`, but uses lookup table first.

## Feature additions

- bytearray() with its methods
- int(x[, base]) with base of 2,8,16 or 0
- int.from_bytes classmethod and int.to_bytes
- str/bytes:
  - translate and maketrans classmethod
  - title, istitle
  - replace() with `count` parameter
- str.format
- bytes(int|iterable|...)
- builtins
  - format
  - hash
  - iter
  - next
- string.Template.substitute
- array Library
- os
  - rename
  - get_terminal_size
  - isatty
  - closerange
  - link, symlink, readlink
  - path:
    - getsize
    - getctime
    - ...
  - ...
  
- add Lib/: shutil, time, timeit

## Patches for Nim-compatibility
- support Android (termux)


## breaks
- `PyDict` is now a ref object now (used to be a `OrderedTableRef`)

- deprecate `toNimStr` of `PyStr`, use `toNimString` if needed (a concerter, so in fact is rarely used by name).
- f/u/b... literal prefix is now for literal only (used to for static[char|string])
- deprcate pylib.timeit, use `pylib/Lib/timeit`'s timeit
