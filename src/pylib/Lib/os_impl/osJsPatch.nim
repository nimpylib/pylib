

when defined(js):
  import std/jsffi
  from ./common import catchJsErrAsCode, catchJsErrAndRaise, PathLike
  import ./posix_like/jsStat
  template existsWrap(existsX, isX) =
    proc existsX*(d: string): bool =
      var s: Stat
      let err = catchJsErrAsCode:
        s = statSync(cstring d)
      if err != 0: return false
      else: s.isX()
  existsWrap dirExists, isDirectory
  existsWrap fileExists, isFile
  existsWrap symlinkExists, isSymbolicLink

  # easy to impl getCreationTime, etc.
  # but that'll introduce the conversions between `DateTime`, which is no need,
  # we just impl the used `get?time`
  func valueOf(obj: Date): c_double{.importcpp.}
  template gen_getxtime(getxtime, attr) =
    proc getxtime*(p: PathLike): float =
      var s: Stat
      let cs = cstring($p)
      catchJsErrAndRaise:
        s = statSync(cs)
      s.attr.valueOf() / 1000
  gen_getxtime getctime, ctime
  gen_getxtime getmtime, mtime
  gen_getxtime getatime, atime


