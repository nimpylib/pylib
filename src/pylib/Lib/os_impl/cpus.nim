
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
