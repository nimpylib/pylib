
when defined(windows):
  proc umask(mode: cint): cint {.importc: "_umask", header: "<sys/stat.h>".}
else:
  import std/posix

import ../common  # raiseErrno

proc umask*(mode: int): int{.discardable.} =
  result =
    when defined(windows): int umask(mode.cint)
    else: int posix.umask(mode.Mode)
  if result < 0:
    raiseErrno()
