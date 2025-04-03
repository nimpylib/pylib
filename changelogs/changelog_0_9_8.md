
# v0.9.8 - 2025-04-03

## break
- chore(nimpatch): now when eq`ver`, patch still added

## Bug Fixes
- Lib/os not compile:
  - getpid
  - iter for os.DirEntry
- Lib/string
  - Template.substitute(dict): not work
  - capwords: with sep had trailing sep
- macos: defined(macosx) shall be always used
- dtoa,pyconfig/floats not compile on arm
- `x**y` when x is not int not complie

### JS
- Lib/os not compile
  - getxtime
  - os_impl.waits
  - getpid: due to `Error: invalid pragma: importDenoOrProcess`
  - scandir


## Fixes for inconsistence with Python
- overwrite Nim's SIGINT handler when not defined pylibUseNimIntHandler
- builtins now contains pyerrors
- str(tuple): now call str on each item
- sugar:
  - now rewrite `func(k=v)`'s v, `(e, ...)`'s e
- sys.hexversion no release and serial; sys.version_info.releaselevel was string over str
- Lib/string Template.substitute:
  - now raises as py
  - no longer uses std/strutils.`%`
  - Template is now a ref object
- chore(nimpatch): nansign:  `nan` might be negative

### inner
- addPatch,platformAvailWhen repr bool expr only shows "true"/"false"

## Feature additions

### builtins
- round(int, int)
- NameError
- KeyboardInterrupt

### Lib
- signal
- resource
- unittest:
  - skipTest
  - assertFalse
  - assert{[Not]{IsInstance,In},IsNot,{Greater,Less}[Equal]}
  - assertRaises(TypeError,...) skipIf,skipUnless
- os:
  - O_* consts
  - wait* func, W* consts
- sys.float_repr_style
- n_string
- string: Template.is_valid,get_identifiers

### inner
- Lib/enum_impl: intEnum, enumType
- pyconfig.util from_c_int
- Python/pylifecycle signal
- errno_impl.errnoUtils.setErrnoRaw
- oserr: newErrnoT new raiseErrnoErrT
- refact(os_impl): Py_get_osfhandle_noraise to util/get_osfhandle

## doc
- comptime/log1p: add origin impl's url
- format: fix warnings
- mustRewriteExtern: condExpr underscore; fix wrong rewrite of strlitQuote
- readme: update old url, use rel url if possible

## CI
- min max
- Lib/string: more for Template
- mv to testaments/:
  - titers,titer_next,tlist 
  - tfloat.nim
  - tdict,tset
- round: more for float

## impr
- faster int(char)
- numTypes.floats: use faster isfinite from isX

## refine
- repr,$: dict,list,set: merge similar code to strIter
### Purge warning
- unused:
  - due to cond branch
  - pyconfig/util.handle_option_bool, jsoserr.jsOs
  - tests/tdecorator.nim
  - itertools: imported but not used sequtils
