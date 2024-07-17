

import ./platform_utils

when weridTarget:
  type time_t* = int  # js number, used as `new Date(value)`'s value
else:
  const
    LP64 = sizeof(int) == sizeof(int64)

  {.push header: "<time.h>".}
  when LP64:
    type time_t*{.importc.} = int64
  elif sizeof(int) == sizeof(int32):
    type time_t*{.importc.} = int32
  else:
    {.error: "unsupported time_t size, only support 64bit and 32 bit system".}
  {.pop.}

const
  SIZEOF_TIME_T* = sizeof time_t
  PY_TIME_T_MAX* = time_t high time_t
  PY_TIME_T_MIN* = time_t low  time_t
