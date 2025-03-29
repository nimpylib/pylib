
import std/posix

type
  struct_rusage* = ref object
    ru_utime*: float
    ru_stime*: float
    ru_maxrss*: int
    ru_ixrss*: int
    ru_idrss*: int
    ru_isrss*: int
    ru_minflt*: int
    ru_majflt*: int
    ru_nswap*: int
    ru_inblock*: int
    ru_oublock*: int
    ru_msgsnd*: int
    ru_msgrcv*: int
    ru_nsignals*: int
    ru_nvcsw*: int
    ru_nivcsw*: int

template doubletime(tv: TimeVal): float =
  float(tv.tv_sec) + float(tv.tv_usec) / 1000000.0

proc toPyObject*(rusage: RUsage): struct_rusage =
  struct_rusage(
    ru_utime: doubletime(rusage.ru_utime),
    ru_stime: doubletime(rusage.ru_stime),
    ru_maxrss: rusage.ru_maxrss,
    ru_ixrss: rusage.ru_ixrss,
    ru_idrss: rusage.ru_idrss,
    ru_isrss: rusage.ru_isrss,
    ru_minflt: rusage.ru_minflt,
    ru_majflt: rusage.ru_majflt,
    ru_nswap: rusage.ru_nswap,
    ru_inblock: rusage.ru_inblock,
    ru_oublock: rusage.ru_oublock,
    ru_msgsnd: rusage.ru_msgsnd,
    ru_msgrcv: rusage.ru_msgrcv,
    ru_nsignals: rusage.ru_nsignals,
    ru_nvcsw: rusage.ru_nvcsw,
    ru_nivcsw: rusage.ru_nivcsw
  )
