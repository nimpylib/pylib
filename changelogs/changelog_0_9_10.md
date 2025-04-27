
# v0.9.10 - 2025-04-27

## Bug Fixes
- py:
    - io.flush raises OSError on SIGXFSZ. (5f2662510)
    - audit funcs; .... (1ad6d96d7)
    - `with` for os.ScandirIterator; add follow_symlinks for DirEntry.stat. (85ee4ec00)
    - OSError([arg]): works. (ac0d45935)
    - stat_result lacks st_file_attributes,st_reparse_tag on Windows. (42acad379)
    - os.makedirs exist_ok was exists_ok. (e48a60a86)
- bool:
    - `echo x` where x has no `$` resulted in pybool called. (9a8d0dc48)
    - bypass(NIM-BUG), fixup! feat(bool): pybool cvt works for Option, `bool`-able: `T is SomeNumber` not compile. (3da7e8659)
- pyconfig:
    - X87_double_rounding was reverted. (e0f0749b0)
    - c_defined reverted;getrandom never declared. (87326ec7c)
- windows:
    - CC crash on dtoa:fixup: fix(builtins): round(float[, n]) not to-even (ref #52). (d26c7861a)
    - oserr: raiseExcWithPath used wrong error code. (538277f28)

### Lib
- unittest:
    - fixup: skipIf,skipUnless that returns a proc not compile.... (ec62e98d1, 6c51835fe)
- resource:
    - not compile on Linux(lack RUSAGE_BOTH,RUSAGE_THREAD). (c54fa07fb)
    - getpagesize not compile; prlimit,setrlimit not work for non tuple types. (bad24cce6)
- signal:
    - SIGXFSZ not ignored. (54d854407)
    - not compile if no Sigset. (10c413cee)
    - not compile on Windows. (6f963f587)
    - lock was nil on Windows. (364bea5e2)
- stat:
    - stat.S_IMODE not compile for Mode. (4625dcc26)
- stat,os.chmod,os.symlink:
    - not compile on Windows. (c626c08e7)
- os:
    - fixup: 'feat(Lib/os): chmod' errmap not compile on Termux. (cd4faa9cc)
    - Windows: unlink not compile. (a331a890e)
- shutils:
    - SameFileError not of PyOSError. (e8d93beb8)
- time:
    - sleep: add audit; fix 1 ms offset. (4531bb939)

### JS
- Lib/os:
    - getpid() not work on js. (ac405b053)
    - not compiles for stat,unlink,chmods,scandir. (2e76c430c)
- oserr/errmap: not compile. (48d0fc3b1)
- os: just import causes not compile. (7fc1a2ec6)
- bypass(NIM-BUG): nim 2.2.4/2.3.1 disallows NonVarDestructor when js. (b3c8121cd)
- denoAttrs:deno detect was reverted, import* not support str as arg. (3153a57e1)

## Feature additions
### builtins
- ops: bitops for ints. (2025f401d)
- bool: pybool cvt works for Option, `bool`-able. (e9eaf8c3f)

### Lib
- os:
    - chmod. (8b96d9566)
    - getppid. (ac405b053)
    - umask. (84c218f8b)
    - lstat, stat with dir_fd, follow_symlinks & fstat. (01b6095e8)
    - exp `supports_*`. (fa4d96974)
    - unlink,remove supports dir_fd. (8af12d918)
    - rmdir supports dir_fd. (4b14bbfcc)
    - scandir supports fd as path. (af5991a9c)
    - DirEntry.is_junction. (1b1653d4a)
    - walk supports followlinks=walk_symlinks_as_files. (2b58ce25a)
    - supports_*.issupperset. (fa0e50041)
    - uname. (50156e634)
- os.path:
    - samestat. (e979be258)
- unittest:
    - self.fail. (5d78aa57f)
    - skip* now will output [SKIPPED] if possible, instead of nothing. (a814951cd)
- sys:
    - audit, addaudithook. (ed7a25407)
    - flags. (04c32a123)
- shutil:
    - rmtree. (8110d1adc)
- EXT:
    - stat.S_I*(Mode): bool. (86698e412)

### inner
- pyconfig: builtin_available,check_func_runtime. (ac14e4441)
- version: wrapPySince, templWrapExportSincePy. (d040f7a5f)
- Python/config_read_env. (5d0659dd7)
- sugar:
    - raise OSError now raises PyOSError over Nim's.... (7a1586ba9)
    - support `except (E,...) [as x]`. (86fbbadaa)

## impr
- Lib/signal: use AC_CHECK_FUNCS. (8e694468d)

## refine
- Lib: use wrapExportSincePy if possible. (a0011fa3d)
- win: dedup IO_REPARSE_TAG_SYMLINK,IO_REPARSE_TAG_MOUNT_POINT. (2b26c3057)

## refactor
- Lib/shutil: split to shutil_impl; add n_shutil. (2544eeaa0)


