
import std/cpuinfo

const vxworks = defined(vxworks)

when vxworks:
  import std/bitops
  proc vxCpuEnabledGet(): uint32{.importc, header: "<vxCpuLib.h>".}

proc cpu_count*(): int =
  when vxworks:
    popcount vxCpuEnabledGet()
  else:
    countProcessors()

import ./posix_like/sched
when HAVE_SCHED_SETAFFINITY:
  proc process_cpu_count*(): int =
    sched_getaffinityImpl(0) do (_: cint):
      inc result
else:
  proc process_cpu_count*(): int = cpu_count()
