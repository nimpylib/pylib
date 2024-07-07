
from ./importer import raiseErrno

# translated from CPython/Python/pytime.c

{.push header: "<time.h>".}

type
  time_t*{.importc.} = int
  struct_tm*{.importc: "struct tm", completeStruct.} = object

const HAVE_STRUCT_TM_TM_ZONE* = sizeof(struct_tm) > 9*sizeof(cint)

when not HAVE_STRUCT_TM_TM_ZONE:
  type Tm*{.importc: "struct tm".} = object
    tm_year*: int  ## years since 1900
    tm_mon*:  range[0 .. 11]
    tm_mday*: range[1 .. 31]
    tm_hour*: range[0 .. 23]
    tm_min*:  range[0 .. 59]
    tm_sec*:  range[0 .. 61]  ## C89 is 0..61, C99 is 0..60
    tm_wday*: range[0 .. 6]
    tm_yday*: range[0 .. 365] 
    tm_isdst*: int
else:
  type Tm*{.importc: "struct tm".} = object
    tm_year*: int  ## years since 1900
    tm_mon*:  range[0 .. 11]
    tm_mday*: range[1 .. 31]
    tm_hour*: range[0 .. 23]
    tm_min*:  range[0 .. 59]
    tm_sec*:  range[0 .. 61]  ## C89 is 0..61, C99 is 0..60
    tm_wday*: range[0 .. 6]
    tm_yday*: range[0 .. 365] 
    tm_isdst*: int
    tm_gmtoff*: clong
    tm_zone*: cstring

when defined(windows):
  proc localtime_s(tm: var Tm, t: var time_t): cint{.importc.}
  proc gmtime_s(tm: var Tm, t: var time_t): cint{.importc.}
else:
  proc localtime_r(t: var time_t, tm: var Tm): ptr Tm{.importc.}
  proc gmtime_r(t: var time_t, tm: var Tm): ptr Tm{.importc.}
proc c_strftime(buf: cstring, len: csize_t, fmt: cstring, tm: var Tm): csize_t{.
  importc: "strftime".}
{.pop.}

template newCCharArr(n): cstring =
  cast[cstring](
    when compileOption("threads"):
      allocShared(n)
    else:
      alloc(n)
  )

proc newZoneCStr*(tm: var Tm): cstring =
  when HAVE_STRUCT_TM_TM_ZONE:
    let allLen = tm.tm_zone.len + 1
    result = newCCharArr(allLen)
    memCopy result, tm.tm_zone, allLen
  else:
    const max_len = 100
    result = newCCharArr(max_len)
    assert 0 != c_strftime(result, max_len, "%Z", tm)

proc freeZoneCStr*(s: cstring) =
    when compileOption("threads"):
      deallocShared(s)
    else:
      dealloc(s)

{.push header: "<errno.h>".}
var errno{.importc.}: cint
let EINVAL{.importc.}: cint
{.pop.}

const in_aix = defined(aix)

proc nTime_localtime*(t: time_t): Tm =
  var t = t
  # as localtime_*'s first param is const pointer,
  # so it's fine to pass a local data's pointer
  when defined(windows):
    let error = localtime_s(result, (t))
    if error != 0:
      errno = error
      raiseErrno()
  else:
    when in_aix and (sizeof(time_t) < 8):
      ##  bpo-34373: AIX does not return NULL if t is too small or too large
      if t < -2145916800 or t > 2145916800:
        errno = EINVAL
        raise newException(OverflowDefect, "localtime argument out of range")
    errno = 0
    if localtime_r((t), result) == nil:
      if errno == 0:
        errno = EINVAL
      raiseErrno()

proc nTime_gmtime*(t: time_t): Tm =
  var t = t
  # as gmtime_*'s first param is const pointer,
  # so it's fine to pass a local data's pointer
  when defined(windows):
    let error = gmtime_s(result, (t))
    if error != 0:
      errno = error
      raiseErrno()
  else:
    if gmtime_r((t), result) == nil:
      when defined(EINVAL):
        if errno == 0:
          errno = EINVAL
      raiseErrno()
