
# v0.9.4 - 2024-10-20

## Bug fixes
- os.DirEntry and its methods not exported
- os: closes #34: DirEntry.is_file() for special file was true for special file (on posix)

- fix(js):
  - denoAttrs.importNodeImpl: wrongly used wrong param (sym over module param)
  - bypass(NIM-BUG): interpolate via ` in emit in template doesn't respect genSym
  - os
    - open forgot to return
    - utime intermedia overflow
    - DirEntry.is_x cannot compile as readlink has sideEffect
- fix(js/nimscript):
  - math.pow: wrongly raises because math_impl.errnoUtils Errno.EDOM was 0 (shall be non-zero)
  - gamma used to return false result sometimes (ref 78ae12124f140e1528b9aedc6bc1887962109ead)

- bypass NIM-BUG
  - bypass(NIM-BUG): JS: internal error: genTypeInfo
  - parentDir cannot work when JS's nimvm

- fix(windows): os.open cannot compile due to lack of errno
- n_timeit.repeat used wrong index, causing IndexDefect
- sys: Py_FORCE_UTF8_FS_ENCODING ignored; linux vm cannot import

### nextafter
- fix(vm): patch.nextafter returning word lo,hi was reversed
- fix: for script backend, nextafter didn't respect sign of 0.0


## Fixes for inconsistence with Python
- python errors were not exported
- JS:
  - v8 bug: Array misses signbit of NANs (storing all just as `NaN`)
  - repr for float/complex makes NaN as "NaN" over "nan"
- rich compare for list, array (array's mixin type comparation respects pylibNoLenient)
- Lib/array: {from,to}file now accepts file-like

## Feature additions

- Lib/array: array('w'): python3.13's Py_UCS4 array; add {from,to}unicode
- EXT:
  - add `as_someinteger_ratio`: used to bypass intermedia overflow in test
  - add `@` method (extension) for array
- functions that now supports JS:
  - os.path.get`x`time
- print: vm supports no newline (set endl arg)

### math functions now accepting float32
- nextafter
- frexp, ldexp
- gamma

### math functions now supports nimvm
- expm1, log1p
- cbrt(float32)

### inner
- version:
  - pysince:
    - accepts stmtList when nimdoc
    - used as condition-expr
- denoAttrs:
    - impr(js): denoAttrs allows 2nd param a dotExpr; fix: os.utime cannot compile for JS
- refactor(pyerrors): split to aritherr
- refactor(math_impl):
  - split inWordUtils from patch/ldexp_frexp

  - impr(math_impl.{from,to}Words): when JS, support compilte-time; faster impl when C-like
  - mv patch/polevl ..

## opt improvement
- use sink for some functions of `array`,`list`,`bytes`,`bytearray`, and mark them as inline
- array: reduce some forloop as block mem op

## Patches for Nim-compatibility
- supports nim 2.2.0
