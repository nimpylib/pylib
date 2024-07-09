
import ./time_t_decl, ./struct_tm_decl
export time_t_decl, struct_tm_decl
import ./pytime  # nPyTime_localtime, nPyTime_gmtime

proc c_strftime(buf: cstring, len: csize_t, fmt: cstring, tm: var Tm): csize_t{.
  importc: "strftime", header: "<time.h>".}

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

proc nTime_localtime*(t: time_t): Tm =
  result.initTm()
  nPyTime_localtime(t, result)

proc nTime_gmtime*(t: time_t): Tm =
  result.initTm()
  nPyTime_gmtime(t, result)
