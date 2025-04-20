
# v0.9.9 - 2025-04-21

## break
- oserr: unexport pathsAsOne, new tryOsOp accepts 2 or 0 paths (3f1f1140)
- slice: toNimSlice is no longer a cvt; cvt toPySlice from PySlice1. (c9518e8f)

## Bug Fixes
- Lib/sys:
  - float_repr_style not export (21b7f793)
- sugar:
  - @a.b, @a.b(1) not compile (0fb94267, 1927cef4)
  - generic class rewrite was wrong; class O(a.c)/O(a[t]) not compile. (f6c2824b)
- list:
  - slice used in get,setitem with negative value causes RangeDefect. (4d33844a)
  - fix setitem discarded longer values. (cd9ed64)
- builtins.slice: toNimSlice's assert not work. (903c1cd)
- initVal_with_handle_signal:
  - deadloop(d9e0a00938e), os.wait*(f25a731fce5). (a5bae2c6)
  - not compile on JS (6534a352)
- fixup! refact(os_impl): Py_get_osfhandle_noraise to util/get_osfhandle. (0f51997b)


### JS
- pyerrors.oserr: new catchJsErrAndSetErrno; add defval for raiseErrno,raiseErrnoWithPath (6534a352)
- importDenoOrNodeMod;2-arg importDenoOrProcess. (8f22a68c)
- os.utime not work: "fs is not defined". (47eca906)
- fixup(d7541b8c4): catchJsErrAsCode (used error which is cstring). (694eae8c)

## Fixes for inconsistence with Python
- Lib/os
  - readlink raises not just FileNotFoundEror,OSError... (c7976a54)
  - makedirs: if existsts_ok, exception might be raised. (90c9610a)
- n_tempfile:
  - js: mktemp raised OSError over FileNotFoundError. (f576b689)

### inner

## Feature additions

### builtins


### Lib
- stat (4c8e84e9)
- unittest:
  - TestCase: addCleanup,tearDown,setUp,run. (3314d922)


### inner
- test: support.os_helper.TESTFN (2c8406a3)
- pyconfig: util.from_c_int_expr,`AC_CHECK_FUNC[S]` (6534a352, be5332b1)
- js:
  - jsutils/consts from_js_const (ae1671e6)


## doc

## CI
- testC,testJs: run iff src/,tests/,./*.nimble, !feat-* branch. (2788f60d)

## impr
- js: os.{open,close}: use importNode over "require...". (f361005c)

## refine

## refactor
- refact: mv os_impl/private/platform_util root's private (1d5e2a8e)
- Lib/unittest: split to unittest/case_py (4853b497)
- Lib/sys: split into sys_impl/; add n_sys (34f0cb98)
- Lib/os_impl: dedup MS_WINDOWS, InJs (6534a352)


### Purge warning
