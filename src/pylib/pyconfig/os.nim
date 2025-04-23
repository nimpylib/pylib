
import ./util
import ./have_x_runtime
const
  DEFAULT_DIR_FD* = from_c_int(AT_FDCWD, "<fcntl.h>", -100)
  AT_SYMLINK_NOFOLLOW* = from_c_int(AT_SYMLINK_NOFOLLOW, "<fcntl.h>", 0x100)

  HAVE_OPENAT* = true
  HAVE_FTRUNCATE* = true

AC_CHECK_FUNC(unlinkat)

check_func_runtime unlinkat, 10.10, 8.0


when HAVE_UNLINKAT_RUNTIME and not declared(unlinkat):
  proc unlinkat*(dir_fd: cint, path: cstring, flag: cint): cint{.importc,
    header: "<unistd.h>".}
  let AT_REMOVEDIR*{.importc, header: "<fcntl.h>".}: cint

