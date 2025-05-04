
import ../private/trans_imp
impExp os_impl,
  consts, posix_like, subp, utils, path, walkImpl, listdirx, randoms, waits,
  have_functions, cpus

when not defined(js):
  import ./os_impl/[
    term, inheritable]
  export term, set_inheritable, get_inheritable

genUname string
import ./os_impl/posix_like/sched
when HAVE_SCHED_SETAFFINITY:
  proc sched_setaffinity*(pid: int, mask: openArray[int]) =
    sched_setaffinityImpl(pid, mask)
  proc sched_getaffinity*(pid: int): seq[int] =
    sched_getaffinityImpl(pid) do (x: cint):
      result.add int x

