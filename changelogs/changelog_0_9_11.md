
# v0.9.11 - 2025-05-25

## Bug Fixes

* py:

  * complex:

    * allow pow's 1arg being SomeNumber; add mixin `==`. (f6f5ba590)
    * pow: more precise for SomeInteger. (5a456efc1)

  * class:

    * attribute expressions were not rewritten. (6fd516c77)
    * top-level classes and methods now properly exported. (a8aeddd91)
    * method order corrected for non-auto restype. (131ec42b0)
    * `:=` now always declares a new variable. (7d1aed865)
* pysugar/class:

  * `super(typ, obj)` parameters were reversed. (67bf79812)
* sugar:

  * `raise a.b...` didn’t compile. (674943b93)
* bool:

  * caused deadloop for `a==b` when `==` not declared. (9278a5d2c)
* Lib:

  * inspect: getsourcelines did not compile. (e3cb4db47)
* doc:

  * Lib/time fetchDoc not working. (0359fac95)

## Feature Additions

### builtins

* `dir(cls)`. (045c692aa)

### Lib

* os:

  * `cpu_count`. (66e693522)
  * `sched_{get,set}affinity`, `process_cpu_count`. (8a87354f7)
* unittest:

  * `TestCase.run`. (f8f17f931)
  * `main`. (8311af01e)
* typing:

  * `OptionalObj`. (f9d6470a5)

### class/sugar

* `cls.dunder.dict.keys` → `cls.__dict__.keys()`. (f48a3fa86)
* auto call `__init_subclass__`. (f65706587)
* support `cls.new` → `cls.__new__`. (3351c5810)
* support `cls(...)` as sugar for `newCls(...)`. (e4db1bab7)
* support chained comparisons (e.g., `1 < x < 3`). (c0b83a61f)
* support Python function calls inside class bodies. (d092211f6)
* support `v: typ` in `def`, where typ can be `Literal`/`Final` → `const`/`let`. (3f2b4d05e)

### pyconfig

* `AC_CHECK_HEADER_THEN_FUNCS`, `AC_CHECK_HEADER[S]`. (d1aec1a9c)

### EXT

* `newPyListOfStr`. (32740352a)
* `OptionalObj`. (f9d6470a5)

## Breaking Changes

* EXT:

  * unexport `io.raiseOsOrFileNotFoundError`. (d9c7dc16c)
* Lib:

  * use `OptionalObj` for `datetime.tzname`, `inspect.*`, `signal.strsignal`, `os.*_cpu_count`. (b4eecd5bb)

## Improvements

* sugar/class:

  * enhanced support for top-level export, method reordering, variable declarations, and expression rewriting. (a8aeddd91, 7d1aed865, 131ec42b0, 6fd516c77)
* doc:

  * updated readme to use `Xxx` instead of `newXxx` for class instantiation. (fb91f6b85)

## Refactor

* os\_impl:

  * reimplemented `posix_like/errnoUtils`; renamed `errnoHandle` to `errnoRaise`. (b75367d93)
* nimpatch:

  * integrated `nim-lang/Nim#23456` to `nimpatch/`. (337b34676)
* exprRewrite:

  * added `mparser` argument to `toPyExpr`. (e4db1bab7)

## Chores

* CI:

  * allow `workflow_dispatch` in docs. (56e3d0d43)
* Nimble:

  * require Nim > 2.0.4; added changelog subcommand; merged logic. (1986af327)

## Workarounds

* os.path.join:

  * support for 3+ arguments (ref d1ca7cd7777a3fb160743). (982f819fe)
* compiles macro:

  * now takes effect when modifying macrocache. (ddc447a22)
