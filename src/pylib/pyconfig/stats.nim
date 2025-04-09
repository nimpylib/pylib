
import ./util
import ./have_x_runtime

AC_CHECK_FUNCS(
  lstat,
  fstatat,
)

check_func_runtime fstatat, 10.10, 8.0
