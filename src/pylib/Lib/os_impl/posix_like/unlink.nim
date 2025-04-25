
import ./unlinkImpl
import ./pyCfg
import ./chkarg
import ../private/iph_utils

importConfig [
  os
]
when InJs:
  template decl(f, val) =
    const `HAVE f` = val
  decl unlinkat, false

proc unlink*[T](p: PathLike[T], dir_fd=DEFAULT_DIR_FD) =
  sys.audit("os.remove", p, if dir_fd==DEFAULT_DIR_FD: -1 else: dir_fd)
  var res: cint
  with_Py_SUPPRESS_IPH:
    when HAVE_UNLINKAT:
      var unlinkat_unavailable = false
      if dir_fd != DEFAULT_DIR_FD:
        when HAVE_UNLINKAT_RUNTIME:
          res = unlinkat(dir_fd.cint, cstring $p, 0)
        else:
          unlinkat_unavailable = true
      else:
        unlinkImpl(p)
    else:
      unlinkImpl(p)
  when HAVE_UNLINKAT:
    if unlinkat_unavailable:
      argument_unavailable_error("dir_fd")
  if res != 0:
    raiseExcWithPath(p)

proc remove*[T](p: PathLike[T], dir_fd=DEFAULT_DIR_FD) =
  ## This function is semantically identical to `unlink`_
  unlink(p, dir_fd)
