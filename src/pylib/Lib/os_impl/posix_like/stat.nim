
import ../common
import ./errno

const DWin = defined(windows)

when DWin:
  when defined(nimPreviewSlimSystem):
    import std/widestrs
  type
    Dev{.importc: "_dev_t", header: "<sys/types.h>".} = c_uint
    Ino = c_ushort
    Time64 = int64
  {.push header: "<sys/stat.h>".}
  type
    Stat{.importc: "struct _stat".} = object
      st_ino*: Ino
      st_mode*: c_ushort
      st_nlink*: c_short
      st_uid*: c_short
      st_gid*: c_short
      st_dev*: Dev  ## same as st_rdev
      st_size*: int64
      st_atime*: Time64
      st_mtime*: Time64
      st_ctime*: Time64
  proc wstat(p: WideCString, res: var Stat): cint{.importc: "_wstat64".}
  proc fstat(fd: cint, res: var Stat): cint{.importc: "_fstat".}
  {.pop.}
else:
  import posix

type
  stat_result* = Stat

proc stat*(path: CanIOOpenT): stat_result =
  ## .. warning:: Under Windows, it's just a wrapper over `_wstat`,
  ##   so this differs from Python's `os.stat` either in prototype and some items of result.
  ##   For details, see https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/stat-functions
  runnableExamples:
    let s = stat(".")
    when defined(windows):
      # _stat's result: st_gid, st_uid is always zero.
      template zero(x) = assert x.int == 0
      zero s.st_gid
      zero s.st_uid

  let ret =
    when path is int:
      fstat(path.cint, result)
    else:
      when DWin:
        wstat( newWideCString(path.fspath), result)
      else:
        stat(cstring path.fspath, result)
  if ret != 0.cint:
    raiseErrno("stat " & $path)
