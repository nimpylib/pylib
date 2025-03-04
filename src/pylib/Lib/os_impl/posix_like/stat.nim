
import ../common
import std/macros


#[ XXX: extact from CPython-3.13-alpha/Modules/posix L1829
  /* The CRT of Windows has a number of flaws wrt. its stat() implementation:
   - time stamps are restricted to second resolution
   - file modification times suffer from forth-and-back conversions between
     UTC and local time
   Therefore, we implement our own stat, based on the Win32 API directly.
*/
TODO: impl our own stat... Get rid of `_wstat`
]#

when InJs:
  import std/jsffi
  import ./jsStat
  template impStatTAttr[T](attr; dstAttr; cvt: typed) =
    func attr*(self: Stat): T =
      let res = self.dstAttr
      if res.isNull:
        raise newException(AttributeError,
          "'os.stat_result' object has no attribute '" & astToStr(attr) & '\'')
      result = cvt[T] res
  template jsToT[T](jsObj: JsObject): T = jsObj.to T
  template impStatTAttr[T](attr; dstAttr) =
    impStatTAttr[T](attr, dstAttr, jsToT)

  template impStatIAttr(attr; dstAttr; typ) =
    type typ = cdouble
    impStatTAttr[typ](attr, dstAttr)
  template impStatIAttr(attr; dstAttr) = impStatTAttr[cdouble](attr, dstAttr)
  impStatIAttr st_ino,    ino,    Ino
  impStatIAttr st_mode,   mode,   Mode
  impStatIAttr st_nlink,  nlink,  Nlink
  impStatIAttr st_uid,    uid,    Uid
  impStatIAttr st_gid,    gid,    Gid
  impStatIAttr st_dev,    dev,    Dev
  impStatIAttr st_rdev,   rdev
  impStatIAttr st_size,   size,   Off
  impStatIAttr st_blocks, blocks, Blkcnt
  impStatIAttr st_blksize,blksize,Blksize

  func rawValueOf(obj: Date): c_double{.importjs: "(#).valueOf()".}
  template chkDate(obj: Date) =
    if obj.isNull:  # may be null on some platform
      raise newException(OSError,
        "get date from stat_result is supported in your platform")
  func dateToSec(obj: Date): float =
    # the number of milliseconds for this date since the epoch
    chkDate obj
    obj.rawValueOf().float / 1000
  func dateToNs(obj: Date): BiggestInt =
    chkDate obj
    BiggestInt obj.rawValueOf()


else:
  const DWin = defined(windows)
  when DWin:
    type Time64 = int64
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

type
  stat_result* = ref object
    data*: Stat ## inner, used by `getattr` of `stat_result`

macro genTimeGetter(amc: static[char]) =
  result = newStmtList()
  let
    js_s_xtime = amc & "time"
    js_xtime = ident js_s_xtime
    js_getxtime = ident("get" & js_s_xtime)
  let s_st_xtim = "st_" & amc & "tim"
  let
    xtim = ident s_st_xtim
    xtime = ident(s_st_xtim & 'e')
  let
    xtime_ns = ident(s_st_xtim & "e_ns")
  result = quote do:
    when InJs:
      func `js_getxtime`*(s: Stat): float =
        ## inner, used by os.path
        s.`js_xtime`.dateToSec()
    func `xtime`*(self: stat_result): float =
      when InJs:
        `js_getxtime` self.data
      else:
        when compiles(self.data.`xtim`):
          self.data.`xtim`.tv_sec.float + self.data.`xtim`.tv_nsec/1_000_000_000
        else:
          self.data.`xtime`.float
    func `xtime_ns`*(self: stat_result): BiggestInt{.pysince(3,3).} =
      when InJs:
        self.data.`js_xtime`.dateToNs()
      else:
        when compiles(self.data.`xtim`):
          self.data.`xtim`.tv_sec.BiggestInt * 1_000_000_000 +
          self.data.`xtim`.tv_nsec.BiggestInt
        else:
          self.data.`xtime`.BiggestInt * 1_000_000_000

genTimeGetter 'a'
genTimeGetter 'm'
genTimeGetter 'c'

{.experimental: "dotOperators".}
template `.`*(self: stat_result; attr): untyped =
  ## as Python's `__getattr__`
  self.data.attr

const visible_size = 10

func getitem(self: stat_result, i: int): BiggestInt =
  # this proc was once generated by macro
  case i
  of 0: result = BiggestInt self.data.st_ino
  of 1: result = BiggestInt self.data.st_mode
  of 2: result = BiggestInt self.data.st_nlink
  of 3: result = BiggestInt self.data.st_uid
  of 4: result = BiggestInt self.data.st_gid
  of 5: result = BiggestInt self.data.st_dev
  of 6: result = BiggestInt self.data.st_size
  of 7: result = BiggestInt self.st_atime
  of 8: result = BiggestInt self.st_mtime
  of 9: result = BiggestInt self.st_ctime
  else:
    raise newException(IndexDefect, "tuple index out of range")

func `[]`*(self: stat_result, i: int): BiggestInt =
  self.getitem(if i < 0: visible_size + i else: i)

func to_result(s: sink Stat): stat_result =
  result = stat_result(data: s)

when defined(js):
  proc statFor(st: var Stat, path: int|PathLike) =
    catchJsErrAndRaise:
      st =
        when path is int:
          fstatSync(path.cint)
        else:
          let cs = cstring($path)
          statSync(cs)

else:
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
