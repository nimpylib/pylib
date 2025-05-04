
import ./[pyCfg]
importConfig [sched]
export HAVE_SCHED_SETAFFINITY
when HAVE_SCHED_SETAFFINITY:
  import ./[errnoUtils, errnoRaise]
  type size_t = uint
  const NCPUS_START = cint sizeof(culong) * 8  ##\
  ## The minimum number of CPUs allocated in a cpu_set_t
  {.push header: "<sched.h>".}
  proc CPU_ALLOC(ncpus: cint): ptr CpuSet {.importc.}
  proc CPU_ALLOC_SIZE(ncpus: cint): size_t {.importc.}
  proc CPU_FREE(set: ptr CpuSet) {.importc.}
  proc CPU_ZERO_S(setsize: size_t, set: ptr CpuSet) {.importc.}
  proc CPU_SET_S(cpu: cint, setsize: size_t, set: ptr CpuSet) {.importc.}
  proc CPU_ISSET_S(cpu: cint, setsize: size_t, set: ptr CpuSet): cint {.importc.}
  proc CPU_COUNT_S(setsize: size_t, set: ptr CpuSet): cint {.importc.}
  {.pop.}

  template PyErr_NoMemory =
    raise newException(OutOfMemDefect, "No memory available")

  template raiseOverflowError(msg) =
    raise newException(OverflowDefect, msg)

  proc sched_setaffinityImpl*[T](pid: int, mask: T#[Iterable[int]]#) =
    let pid = Pid pid
    var ncpus = NCPUS_START
    var setsize = CPU_ALLOC_SIZE(ncpus)
    var cpu_set = CPU_ALLOC(ncpus)
    if cpu_set.isNil:
      PyErr_NoMemory()
    CPU_ZERO_S(setsize, cpu_set)

    template error =
      if not cpu_set.isNil:
        CPU_FREE(cpu_set)
    for cpu in mask:
      if cpu < 0:
        error
        raise newException(ValueError, "Negative CPU number")
      if cpu > cint.high.int - 1:
        error
        raiseOverflowError("CPU number too large")
      let cpu = cast[cint](cpu)
      if cpu >= ncpus:
        # Grow CPU mask to fit the CPU number
        var newncpus = ncpus
        while newncpus <= cpu:
          if newncpus > typeof(newncpus).high div 2:
            newncpus = cpu + 1
          else:
            newncpus *= 2
        let newmask = CPU_ALLOC(newncpus)
        if newmask.isNil:
          error
          PyErr_NoMemory()
        let newsetsize = CPU_ALLOC_SIZE(newncpus)
        CPU_ZERO_S(newsetsize, newmask)
        copyMem(newmask, cpu_set, setsize)
        CPU_FREE(cpu_set)
        setsize = newsetsize
        cpu_set = newmask
        ncpus = newncpus
      CPU_SET_S(cpu, setsize, cpu_set)

    if sched_setaffinity(pid, setsize, cpu_set) != 0:
      CPU_FREE(cpu_set)
      raiseErrno()
    CPU_FREE(cpu_set)

  proc sched_getaffinityImpl*(pid: int, cb: proc (cpu: cint)) =
    let pid = Pid pid
    var ncpus = NCPUS_START
    var setsize: size_t
    var mask: ptr CpuSet

    while true:
      setsize = CPU_ALLOC_SIZE(ncpus)
      mask = CPU_ALLOC(ncpus)
      if mask.isNil:
        PyErr_NoMemory()
      if sched_getaffinity(pid, setsize, mask) == 0:
        break
      CPU_FREE(mask)
      if not isErr EINVAL:
        raiseErrno()
      #if ncpus > int.high div 2: raise newException(OverflowError, "Could not allocate a large enough CPU set")
      ncpus *= 2

    var cpu = cint 0
    var count = CPU_COUNT_S(setsize, mask)
    while count > 0:
      if 0 != CPU_ISSET_S(cpu, setsize, mask):
        cb cpu
        dec count
      inc cpu
    CPU_FREE(mask)
