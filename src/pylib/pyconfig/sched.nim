
import ./util

AC_CHECK_FUNCS(
  sched_setaffinity
)

when HAVEsched_setaffinity:
  import std/posix
  export Pid
  type CpuSet*{.importc: "cpu_set_t", header: "<sched.h>".} = object
  proc sched_setaffinity*(pid: Pid, cpusetsize: uint, mask: ptr CpuSet): cint{.importc, header: "<sched.h>".}
  proc sched_getaffinity*(pid: Pid, cpusetsize: uint, mask: ptr CpuSet): cint{.importc, header: "<sched.h>".}


