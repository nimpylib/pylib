
# v0.9.2 - 2024-08-16

## Bug fixes
- math.isinf, isfinite didn't consider negative infinity as infinity.
- dict.copy() not compile
- mixing PyBool and bool not compile e.g.`True and true`
- bytearray.toNimString not work


## Fixes for inconsistence with Python
- float("-nan") may returns NaN with positive sign bit
- int(obj), float(obj) now works for obj with trunc/index
- complex(obj) for `obj: str or Any`
- input/print uses sys.stdin.sys.stdout as in/out stream
- `dict(k=v)`'s `K` is now str over string
- supports list, set, dict used as type(typedesc)
- os.path.getsize on non-reg is not allowed
- time.strftime supports %j %u %w %U and str{f,p}time supports %F %T
- repr
  - uses lower hex alpha instead of upper and repr(bytes)
  - repr(bytes) works for char greater than '\127'
- print(..., file=None) will do nothing if sys.stdout == Non
- check for isspace of str now handles '\x1c'..'\x1f'
- Lib
  - tempfile
    - split Lib/tempfile as n_tempfile, tempfile; fix signatures as py's
  - sys
    - fix io.flush not export by sys
  - io
    - DEFAULT_BUFFER_SIZE is exported now
    - context mgr for io.IOBase
  - os
    - stat_result's `__getattr__`  returned int over float

## Feature additions
- int.to_bytes and int.from_bytes classmethod
- int.bit_count
- float.as_integer_ratio
- float.hex and float.fromhex classmethod
- support `**` where rhs is static negative int
- frozenset
- `PyUnicode[Decode]Error`
- Lib/
  - gc
  - datetime
  - unittest
  - sys
    - getfilesystemencoding()
    - dunder_std{in,out,err}  (a.k.a. `__std*__`)
  - pathlib.Path:
    - rel/abs relative methods
    - joinpath,`/` and getters
    - open, {write,read}_{text,bytes}
    - some of `is_*`
    - filesystem-relative method
  - timeit.*, (not just .timeit)
  - os
    - add JS support for most APIs
    - `{get,set}_[handle_]inheritable`
    - lseek
    - `SEEK_*` constants
    - getpid

### Nimscript Support Addition
input print

### nimvm Support Addition
- math.ldexp,isinf,isfinite


## Patches for Nim-compatibility
- supports Debian

## Python Sugar
- impr: better error msg for `def f:` (without `(`)
