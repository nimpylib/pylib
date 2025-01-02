
# v0.9.3 - 2024-09-30

## Breaks
- `PyComplex[T]` -> `PyTComplex[T]`; PyComplex is now non-generics (like CPython's `Py_complex`)

## Bug fixes
- Lib/pathlib: argument order of Path.{sym,hard}link_to was reversed
- os.utime not compile on x86_64 macos

### math
- expm1, log1p was inaccurate for arg near 0
- dist's signature was wrong ( used to be `func [F: SomeFloat](x, y: F): F` )
- `degrees` was typed as `degress`
- log1p, expm1 not accurate for arg near 0; 


## Fixes for inconsistence with Python
- math.{floor,ceil,trunc} now return int over float
- str for complex(N, nan) was "(Nnanj)" (shall be "nanj") and str(complex) returns something in form of `Complex(re: A, im: B)`
- Lib/math's functions raises exception as Python does when math error occurs
- Lib/math:
  - dist's signature wrongly used that of hypot
  - `degrees` was typed as degress

## Feature additions
- pow for complex type


### math
- supports objc (not test yet)
- supports compiletime (nimvm)
- for JS:
  - math
    - gamma, lgamma, erf, erfc are supported
    - ldexp is more accurate

- math:
  - cbrt
  - sumprod, dist, hypot
  - nextafter, ulp
  - ...  (all APIs in CPython's math)

- pathlib:
  - `/=` for Path


## Patches for Nim-compatibility