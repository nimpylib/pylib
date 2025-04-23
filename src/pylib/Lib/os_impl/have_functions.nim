
import ../../pyconfig/[
  os, chmods, stats,
]
{.push warning[UnusedImport]: off.}
import ./posix_like  # used at compile-time
{.pop.}

import std/sets
import std/macros

type
  HaveFuncOrig = HashSet[string]
  HaveFunc = distinct HaveFuncOrig
proc incl(s: var HaveFunc, i: string){.borrow.}
proc contains(s: HaveFunc, i: string): bool{.borrow.}
proc len(s: HaveFunc): int{.borrow.}

proc `$`*(s: HaveFunc): string =
  result = "{"
  if s.len == 0:
    result.add '}'
    return
  for i in HaveFuncOrig s:
    result.add i  # no quote
    result.add ", "
  let le1s = result.len-1
  result.setLen le1s
  result[le1s-1] = '}'

func removeOsPrefix(fn: string): string =
  if fn.len < 3:
    return fn
  if fn[0] == 'o' and fn[1] == 's' and fn[2] == '.':
    return fn[3..^1]
  fn

template contains*(s: HaveFunc; fn: untyped): bool =
  bind contains, removeOsPrefix
  s.contains astToStr(fn).removeOsPrefix

proc multiContainsImpl(s, fns: NimNode): NimNode =
  result = newLit(true)
  for fn in fns:
    result = infix(result,
      "and",
      newCall(bindSym"contains", s, fn),
    )

macro contains*(s: HaveFunc; fns: varargs[untyped]): bool =
  ## used for `{xxx, ...} <= s`
  multiContainsImpl(s, fns)

macro `>=`*(s: HaveFunc; fns: untyped): bool =
  ## used for `{xxx, ...} <= s`
  multiContainsImpl(s, fns)

# Not work for even `(x, ...) <= s`:
template `<=`*(fns: untyped; s: untyped): bool = bind `>=`; s>=fns

const MS_WINDOWS = defined(windows)
template reset_set(name){.dirty.} =
  var `v name`{.compileTime.} = HaveFunc initHashSet[string]()
  template sset: untyped{.redefine.} = `v name`

template sset_add(fn) =
  static:
    sset.add astToStr fn

template sadd(str, fn) =
  when declared(fn) and declared(str):
    when str:
      static:
        sset_add fn

template exp(n) =
  const n* = `v n`

#[
reset_set supports_dir_fd
sadd HAVE_OPENAT, os.open, os.stat, os.unlink, os.rmdir}

reset_set supports_fd
sadd HAVE_FDOPENDIR,  scandir

os.stat in os.supports_follow_symlinks
]#


when true:
    reset_set supports_dir_fd
    template add(s: HaveFunc; fn: string) =
      bind incl
      s.incl fn

    sadd(HAVE_FACCESSAT,  access)
    sadd(HAVE_FCHMODAT,   chmod)
    sadd(HAVE_FCHOWNAT,   chown)
    sadd(HAVE_FSTATAT,    stat)
    sadd(HAVE_FUTIMESAT,  utime)
    sadd(HAVE_LINKAT,     link)
    sadd(HAVE_MKDIRAT,    mkdir)
    sadd(HAVE_MKFIFOAT,   mkfifo)
    sadd(HAVE_MKNODAT,    mknod)
    sadd(HAVE_OPENAT,     open)
    sadd(HAVE_READLINKAT, readlink)
    sadd(HAVE_RENAMEAT,   rename)
    sadd(HAVE_SYMLINKAT,  symlink)
    sadd(HAVE_UNLINKAT,   unlink)
    sadd(HAVE_UNLINKAT,   rmdir)
    sadd(HAVE_UTIMENSAT,  utime)

    reset_set supports_effective_ids
    sadd(HAVE_FACCESSAT,  access)

    reset_set supports_fd
    sadd(HAVE_FCHDIR,     chdir)
    sadd(HAVE_FCHMOD,     chmod)
    sadd(MS_WINDOWS,      chmod)
    sadd(HAVE_FCHOWN,     chown)
    sadd(HAVE_FDOPENDIR,  listdir)
    sadd(HAVE_FDOPENDIR,  scandir)
    sadd(HAVE_FEXECVE,    execve)
    sset_add(stat) # fstat always works
    sadd(HAVE_FTRUNCATE,  truncate)
    sadd(HAVE_FUTIMENS,   utime)
    sadd(HAVE_FUTIMES,    utime)
    sadd(HAVE_FPATHCONF,  pathconf)
    if declared(statvfs) and declared(fstatvfs): # mac os x10.3
        sadd(HAVE_FSTATVFS, statvfs)

    reset_set supports_follow_symlinks
    sadd(HAVE_FACCESSAT,  access)
    # Some platforms don't support lchmod().  Often the function exists
    # anyway, as a stub that always returns ENOSUP or perhaps EOPNOTSUPP.
    # (No, I don't know why that's a good design.)  ./configure will detect
    # this and reject it--so HAVE_LCHMOD still won't be defined on such
    # platforms.  This is Very Helpful.
    #
    # However, sometimes platforms without a working lchmod() *do* have
    # fchmodat().  (Examples: Linux kernel 3.2 with glibc 2.15,
    # OpenIndiana 3.x.)  And fchmodat() has a flag that theoretically makes
    # it behave like lchmod().  So in theory it would be a suitable
    # replacement for lchmod().  But when lchmod() doesn't work, fchmodat()'s
    # flag doesn't work *either*.  Sadly ./configure isn't sophisticated
    # enough to detect this condition--it only determines whether or not
    # fchmodat() minimally works.
    #
    # Therefore we simply ignore fchmodat() when deciding whether or not
    # os.chmod supports follow_symlinks.  Just checking lchmod() is
    # sufficient.  After all--if you have a working fchmodat(), your
    # lchmod() almost certainly works too.
    #
    # sadd(HAVE_FCHMODAT,   chmod)
    sadd(HAVE_FCHOWNAT,   chown)
    sadd(HAVE_FSTATAT,    stat)
    sadd(HAVE_LCHFLAGS,   chflags)
    sadd(HAVE_LCHMOD,     chmod)
    sadd(MS_WINDOWS,      chmod)
    if declared(lchown): # mac os x10.3
        sadd(HAVE_LCHOWN, chown)
    sadd(HAVE_LINKAT,     link)
    sadd(HAVE_LUTIMES,    utime)
    sadd(HAVE_LSTAT,      stat)
    sadd(HAVE_FSTATAT,    stat)
    sadd(HAVE_UTIMENSAT,  utime)
    sadd(MS_WINDOWS,      stat)

exp supports_dir_fd
exp supports_effective_ids
exp supports_fd
exp supports_follow_symlinks
