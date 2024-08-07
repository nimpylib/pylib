
import ./n_timeit
import ../noneType
import ../builtins/list
import ./sys
export list, noneType

export n_timeit except newTimer, repeat, print_exc


template repeat*(xs: varargs[untyped]): PyList[float] =
  bind repeat, list
  list repeat(xs)

template autorange*(self: Timer, callable=None): (int, float) =
  bind autorange
  autorange(self, nil)

template sys_stderr: untyped = sys.stderr
proc print_exc*(self: Timer, file: NoneType|File|typeof(sys.stderr) = None) =
  bind print_exc, sys_stderr
  print_exc(self,
    when file is NoneType: sys_stderr
    else: file
  )
