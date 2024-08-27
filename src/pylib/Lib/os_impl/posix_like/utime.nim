## os.utime

import std/os
import std/times
import std/macros
import ../common
include ./ncommon

type
  TimePair*[T: int|float] = tuple
    atime, mtime: T
  TimeNsPair* = tuple
    atime_ns, mtime_ns: int

  
when InJs:
  type Time = cdouble
  proc utimesSync(path: cstring, atime, ctime: Time){.importDenoOr(fs, utimesSync).}
  proc lutimesSync(path: cstring, atime, ctime: Time){.importDenoOr(fs, lutimesSync).}

  template stoTime(s: int|float): Time = Time s
  template utimeImpl(mapper; path: PathLike, times; follow_symlinks=true) =
    let
      jsS = cstring $path
      tup = mapper times
    catchJsErrAndRaise:
      if follow_symlinks:
        utimesSync jsS, tup.atime, tup.ctime
      else:
        lutimesSync jsS, tup.atime, tup.ctime

else:
  func divmod(x, y: int): (int, int) =
    ## for Positive only
    (x div y, x mod y)

  const `ns/s` = 1_000_000_000
  when defined(windows):
    template stoTime(s: int): times.Time = fromUnix(s)
    template stoTime(s_ns: float): times.Time = fromUnixFloat s_ns

    proc nstoTime(tot_ns: int): times.Time =
      let (s, ns) = divmod(tot_ns, `ns/s`)
      initTime(s, ns)
    const FILE_WRITE_ATTRIBUTES = 0x100
    proc openHandle(path: string, follow_symlinks=true): Handle =
      var flags = FILE_FLAG_BACKUP_SEMANTICS or FILE_ATTRIBUTE_NORMAL
      if not follow_symlinks:
        flags = flags or FILE_FLAG_OPEN_REPARSE_POINT

      result = createFileW(
        newWideCString(path), FILE_WRITE_ATTRIBUTES, 0,
        nil, OPEN_EXISTING, flags, 0
      )
    proc utimeAux(file: string, times: tuple[atime, mtime: times.Time], follow_symlinks=true): bool =
      let h = openHandle(file, follow_symlinks=follow_symlinks)
      if h == INVALID_HANDLE_VALUE:
        return true
      var
        lastAccess = times.atime.toWinTime.toFILETIME
        lastWrite  = times.mtime.toWinTime.toFILETIME
      let res = setFileTime(h, nil, lastAccess.addr, lastWrite.addr)
      discard h.closeHandle
      if res == 0'i32:
        return true
  else:
    template initTimeval(s, us): untyped =
      Timeval(tv_sec: posix.Time(s), tv_usec: Suseconds us)
    func stoTime(s: int): Timeval = initTimeval(s, 0)
    func stoTime(s_ns: float): Timeval =
      let
        s_int = BiggestInt s_ns
        us = (s_ns - s_int.float) * 1e6
      initTimeval(s_int, us)
    func nstoTime(ns: int): Timeval =
      let tot_us = ns div 1000
      let (s_int, us_int) = divmod(tot_us, 1_000_000)
      initTimeval(s_int, us_int)

    proc utimeAux(file: string, timevals: tuple[aTimeval, mTimeval: posix.Timeval], follow_symlinks=true): bool =
      # [last access, last modification]
      var arr = [timevals[0], timevals[1]]
      if utimes(file, arr.addr) != 0:
        return true

  macro mapTup(tup: tuple, mapper): tuple =
    ## t -> (t[0].mapper, ...)
    expectKind tup, {nnkIdent, nnkSym}  # no literal allowed!
    result = newNimNode nnkTupleConstr
    for i in 0..<tup.getTypeImpl.len:
      result.add newCall(mapper, newCall("[]", tup, i.newLit))

  template utimeImpl(mapper; path: PathLike, times; follow_symlinks=true) =
    let spath = $path
    if spath.utimeAux(mapTup(times, mapper), follow_symlinks=follow_symlinks):
      raiseExcWithPath path

proc utime*[T; N](path: PathLike[T], times: TimePair[N], follow_symlinks=true){.noWeirdTarget.} =
  utimeImpl stoTime, path, times, follow_symlinks
proc utime*[T](path: PathLike[T], ns: TimeNsPair, follow_symlinks=true){.noWeirdTarget.} =
  utimeImpl nstoTime, path, ns, follow_symlinks
proc utime*[T](path: PathLike[T], follow_symlinks=true){.noWeirdTarget.} =
  let
    nowTime = times.getTime()
    ns = nowTime.toUnix.int * `ns/s` + nowTime.nanosecond
    times_tup = (ns, ns)
  utimeImpl nstoTime, path, times_tup, follow_symlinks
