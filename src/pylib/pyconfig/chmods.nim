
import ./util
import ./have_x_runtime

AC_CHECK_FUNCS(
  chmod,
  fchmod,
  fchmodat,
)

when defined(linux):
  # Force lchmod off for Linux. Linux disallows changing the mode of symbolic
  # links. Some libc implementations have a stub lchmod implementation that always
  # returns an error.
  const HAVE_LCHMOD* = false
else:
  AC_CHECK_FUNC(lchmod)

check_func_runtime fchmodat, 10.10, 8.0

