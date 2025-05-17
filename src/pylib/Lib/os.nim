## see docs.python.org/3/library/os.html
## 
## Also export everything of std/os
## 
## .. warning:: export of std/os will be removed in 0.10.0

import std/os as std_os
export std_os

import ./os_impl/private/platform_utils
import ../pyconfig/bootstrap_hash

import ./n_os
export n_os except scandir, DirEntry, urandom, getrandom, genUname, uname, uname_result,
  sched_getaffinity, sched_setaffinity,
  cpu_count, process_cpu_count
import ./typing_impl/optional_obj
expOptObjCvt()
import ../version
genUname PyStr
template scandir*(): untyped{.pysince(3,5).} = n_os.scandir()
template scandir*[T](p: PathLike[T]): untyped{.pysince(3,5).} = n_os.scandir(p)
template scandir*(p: int): untyped{.pysince(3,5).} = n_os.scandir(p)
pysince(3,5):
  export DirEntry

template close*(p: DirEntry){.pysince(3,6).} = discard

proc urandom*(size: int): PyBytes =
  bytes n_os.urandom(size)

proc getrandom*(size: int, flags = 0): PyBytes{.
    platformAvailWhen(linux, have_getrandom_syscall), pysince(3,6).} =
  bytes n_os.getrandom(size, flags)

import ./os_impl/posix_like/sched
when HAVE_SCHED_SETAFFINITY:
  from ./collections/abc import Iterable
  import ../builtins/set
  proc sched_setaffinity*(pid: int, mask: Iterable[int]) =
    sched_setaffinityImpl(pid, mask)
  proc sched_getaffinity*(pid: int): PySet[int] =
    result = newPySet[int]()
    sched_getaffinityImpl(pid) do (x: cint):
      result.add int x

template wrapMayNone(name){.dirty.} =
  proc name*(): OptionalObj[int] =
    let res = n_os.name()
    if res > 0: newOptionalObj(res)
    else: newOptionalObj[int]()

wrapMayNone cpu_count
wrapMayNone process_cpu_count
