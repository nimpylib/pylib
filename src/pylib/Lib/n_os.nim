
import ../private/trans_imp
impExp os_impl,
  consts, posix_like, subp, utils, path, walkImpl, listdirx, randoms, waits,
  have_functions

when not defined(js):
  import ./os_impl/[
    term, inheritable]
  export term, set_inheritable, get_inheritable



