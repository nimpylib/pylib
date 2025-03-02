
# v0.9.7 - 2025-03-02

## break
- nitertools -> `n_itertools`; use openArray over seq

## Bug Fixes
- sorted not compile for ptr list, etc and for generics seq
- complex(int,int) not compile
- datetime.timedelta not compile

## Fixes for inconsistence with Python
- zip: not compile `Iterable[T]` (T differs each other)
- builtins.round(float[, n]) not to-even
- str(Inf) -> Infinity when JS (#44)
- int(char) err msg differs py's

## Feature additions
### Lib
- collections.abc: include iters, collections, asyncs, generators
- bisect and `n_bisect`
- random (all func besides randint,seed,choice,Random)
- itertools.accumulate
- os.urandom, os.getrandom
- builtins

### builtins
- allow items(tuple)
- max/min supports iterable & keywords
- format
- dir

### in `def` (func body)
- support equal sign minus like `x=-1`/`x==-1`

### EXT
- `@` for Sequence
- bytes: init from openArray[uint8] or Iterable[SomeInteger]

### inner
- Objects/obmalloc.nim: pyalloc pyfree
- /pyconfig:
  - pycore/pymath
  - `c_defined`, `py_getrandom`
- `os_impl.platformAvailWhen`

## Patches for Nim-compatibility
- newUninit for nim before 2.1.1

## CI
- update actions/cache@v2 to @v4
- mv tfloat.nim tests tests/testament

## impr
- faster int(char)
- numTypes.floats: use faster isfinite from isX

