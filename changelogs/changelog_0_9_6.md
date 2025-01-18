
# v0.9.6 - 2025-01-18

## Bug Fixes
- Lib/errno cannot be compiled in Windows (931a9f50cecf2b75de214)
- `except` claude with no exception type (e.g. `except:`) crashes compiler
- Lib/platform: machine() result fixed for some arch; closes #48

## Fixes for inconsistence with Python
- `pass expr` was supported instead of `pass` (:use `discard expr` instead)
- zip: support no-seq args and any number of args over only 2; allow non-static `strict`
- triple strlit won't be escape-translated
- `except` with no exc type (e.g. `except:`) not compile

## Feature additions
### print
- allow **\`end\`** along with `endl` for keyword

### in `def` (func body)
- literal will be automatically interpreted as Py list/set/dict/str
- support `__getitem__`, `__setitem__` and `__delitem__` syntax (e.g. `ls[1:3]`)
- strlitCat in def (e.g. `"asds" "sad"`)

### inner
- doc(pylib.nim): add version info in doc output
- EXT: nextImpl
## Patches for Nim-compatibility

## CI
- add tests/testament
- doc will be deployed to `docs.nimpylib.org`

## impr
- tonim: no list will be initialized when unpacking an array
- print: `sep`,`endl`'s default value is now char over string
