
import ./util

when defined(linux):
  c_defined have_getrandom, "HAVE_GETRANDOM", ["<sys/random.h>"]
  c_defined have_getrandom_syscall, "HAVE_GETRANDOM_SYSCALL", ["<sys/random.h>"]
else:
  const
    have_getrandom* = false
    have_getrandom_syscall* = false

const py_getrandom* = have_getrandom or have_getrandom_syscall
