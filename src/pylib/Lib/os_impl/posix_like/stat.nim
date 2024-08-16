
import ../common

const DWin = defined(windows)

type Time64 = int64

#[ XXX: extact from CPython-3.13-alpha/Modules/posix L1829
  /* The CRT of Windows has a number of flaws wrt. its stat() implementation:
   - time stamps are restricted to second resolution
   - file modification times suffer from forth-and-back conversions between
     UTC and local time
   Therefore, we implement our own stat, based on the Win32 API directly.
*/
TODO: impl our own stat... Get rid of `_wstat`
]#
when DWin:
  when defined(nimPreviewSlimSystem):
    import std/widestrs
  type
    Dev{.importc: "_dev_t", header: "<sys/types.h>".} = c_uint
    Ino = c_ushort
    Mode = c_ushort
    Nlink = c_short
    Uid = c_short
    Gid = c_short
    Off = int64
    
  {.push header: "<sys/stat.h>".}
  type
    Stat{.importc: "struct _stat64".} = object
      st_ino*: Ino
      st_mode*: Mode
      st_nlink*: Nlink
      st_uid*: Uid
      st_gid*: Gid
      st_dev*: Dev  ## same as st_rdev on Windows
      st_size*: Off
      st_atime*: Time64
      st_mtime*: Time64
      st_ctime*: Time64
  proc wstat(p: WideCString, res: var Stat): cint{.importc: "_wstat64".}
  proc fstat(fd: cint, res: var Stat): cint{.importc: "_fstat64".}
  {.pop.}
else:
  import std/posix
  
  template toTime(x): untyped = x.tv_sec
  template st_atime*(s: Stat): untyped = Time64 toTime s.st_atim
  template st_mtime*(s: Stat): untyped = Time64 toTime s.st_mtim
  template st_ctime*(s: Stat): untyped = Time64 toTime s.st_ctim

const statHasMore = defined(linux)  # XXX: this check is not suitable.
when statHasMore:
  type
    stat_result* = tuple[
      st_mode: Mode, st_ino: Ino, st_dev: Dev, st_nlink: Nlink,
      st_uid: Uid, st_gid: Gid, st_size: Off,
      st_atime, st_mtime, st_ctime: Time64,

      st_blocks: Blkcnt,
      st_blksize: Blksize,
      st_rdev: Dev,
      # st_flags
    ]  ## Python's `os.stat_result` (a NamedTuple)
else:
  type
    stat_result* = tuple[
      st_mode: Mode, st_ino: Ino, st_dev: Dev, st_nlink: Nlink,
      st_uid: Uid, st_gid: Gid, st_size: Off,
      st_atime, st_mtime, st_ctime: Time64,
    ]  ## Python's `os.stat_result` (a NamedTuple)

import std/macros

macro to_result(s: Stat): stat_result =
  var templ: stat_result
  result = nnkTupleConstr.newNimNode
  for kStr, _ in templ.fieldPairs:
    let k = ident kStr
    result.add newColonExpr(k, newDotExpr(s, k))
    #  `k`: `s`.`k`

proc statFor(st: var Stat, path: int|PathLike) =
  let ret =
    when path is int:
      fstat(path.cint, st)
    else:
      when DWin:
        wstat( newWideCString(path.fspath), st)
      else:
        stat(cstring path.fspath, st)
  if ret != 0.cint:
    when path is int:
      raiseErrno($path)
    else:
      path.raiseErrnoWithPath()

template statAttr*(path: PathLike|int, attr: untyped): untyped =
  ## stat(`path`).`attr`
  var st{.noinit.}: Stat
  st.statFor path
  st.attr

template statAux: stat_result =
  var st{.noinit.}: Stat
  st.statFor path
  to_result st

proc stat*(path: int): stat_result = statAux
proc stat*[T](path: PathLike[T]): stat_result =
  ## .. warning:: Under Windows, it's just a wrapper over `_wstat`,
  ##   so this differs from Python's `os.stat` either in prototype
  ##   (the `follow_symlinks` param is not supported) and some items of result.
  ##   For details, see https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/stat-functions
  runnableExamples:
    let s = stat(".")
    when defined(windows):
      # _stat's result: st_gid, st_uid is always zero.
      template zero(x) = assert x.int == 0
      zero s.st_gid
      zero s.st_uid
  statAux
