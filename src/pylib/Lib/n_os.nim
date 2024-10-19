
import ./os_impl/[
  consts, posix_like, subp, utils, path, walkImpl, listdirx,
]
when not defined(js):
  import ./os_impl/[
    term, inheritable]
  export term, set_inheritable, get_inheritable

export
  consts, posix_like, subp, utils, path, walkImpl, listdirx


