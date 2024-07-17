
import ./struct_tm_decl
import ./time_utils
import ./platform_utils

when not weridTarget:
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
  when defined(js):
    tm.tm_zone
  elif defined(nimscript):
    {.error:"not available in NimScript".}
    ""
  else:
    when HAVE_STRUCT_TM_TM_ZONE:
      let allLen = tm.tm_zone.len + 1
      result = newCCharArr(allLen)
      memCopy result, tm.tm_zone, allLen
    else:
      const max_len = 100
      result = newCCharArr(max_len)
      assert 0 != c_strftime(result, max_len, "%Z", tm)

proc freeZoneCStr*(s: cstring) =
  when weridTarget: discard
  else:
    when compileOption("threads"):
      deallocShared(s)
    else:
      dealloc(s)

when defined(js):
  static: assert HAVE_STRUCT_TM_TM_ZONE
  proc zonename*(tm: var Tm): string =
    # assuming JS's timezone name is always valid to convert to UTF-8
    $tm.tm_zone
else:
  import ../../../../Python/unicodeobject/locale_codec

  proc zonename*(tm: var Tm): string =
    var zone = newZoneCStr tm
    result = PyUnicode_DecodeLocale(zone, "surrogateescape")
    zone.freeZoneCStr()
