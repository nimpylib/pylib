

when defined(js):
  from ./common import catchJsErrAsCode
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
  template gen_getxtime(getxtime) =
    proc getxtime*(p: PathLike): float =
      var s: Stat
      let err = catchJsErrAndRaise :
        s = statSync(cstring d)
      s.getxtime

