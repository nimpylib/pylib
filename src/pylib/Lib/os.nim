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
export n_os except scandir, DirEntry, urandom, getrandom

import ../version

template scandir*(): untyped{.pysince(3,5).} = n_os.scandir()
template scandir*[T](p: PathLike[T]): untyped{.pysince(3,5).} = n_os.scandir(p)
pysince(3,5):
  export DirEntry

template close*(p: DirEntry){.pysince(3,6).} = discard

proc urandom*(size: int): PyBytes =
  bytes n_os.urandom(size)

proc getrandom*(size: int, flags = 0): PyBytes{.
    platformAvailWhen(linux, have_getrandom_syscall), pysince(3,6).} =
  bytes n_os.getrandom(size, flags)
