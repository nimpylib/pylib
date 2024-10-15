
import ./n_timeit
import ../noneType
import ../builtins/list
import ../version
import ./sys
export list, noneType

pysince(3,3):
  const TimeItUseTime*{.booldefine: "timeit.usetime".} = true  ## \
    ## disable this if don't wanna depending on `Lib/time`
  when TimeItUseTime:
    import ./time

export n_timeit except newTimer, repeat, print_exc, default_repeat, default_timer

when TimeItUseTime:
  var default_timer* = pysince(3.3, time.perf_counter, n_timeit.default_timer)
else: export n_timeit.default_timer

template repeatImpl(xs: varargs[untyped]): untyped = n_timeit.repeat(xs)  ##\
## to avoid `repeat`'s repeat param being replaced

const default_repeat* = pysince(3.7, 5, 3)  ##\
  ## since python 3.7: default value of `repeat` parameter is changed from 3 to 5.

template repeat*(
    stmt: TimeitParam = NullStmt;
    setup: TimeitParam = NullStmt;
    timer=default_timer, repeat=pysince(3.7, 5, 3), #[here uses inline for clearer doc]#
    number=default_number): PyList[float] =
  runnableExamples:
    assert len(repeat(repeat=0)) == 0
  bind repeatImpl, list
  var repeatVal{.noInit.} = repeat
  ##[ XXX: NIM-BUG:
  currently NIM will unconditionally init `repeatVal` (a.k.a. firstly set to 0)
  even though it's marked as `let` (readonly variable).
  if using `let repeatVal = ...`, C' compile complains sth like:
    `error: assignment of read-only variable 'repeatValX60gensym0___timeit95examples951_u5'`
  ]##
  list repeatImpl(stmt, setup, timer, repeatVal, number)


template repeat*(self: Timer, repeat=pysince(3.7, 5, 3), #[here uses inline for clearer doc]#
    number=default_number): PyList[float] =
  bind list
  var repeatVal{.noInit.} = repeat
  list n_timeit.repeat(self, repeatVal,number)

template autorange*(self: Timer, callable=None): (int, float){.pysince(3,6).} =
  bind autorange
  autorange(self, nil)

template sys_stderr: untyped = sys.stderr
proc print_exc*(self: Timer, file: auto = None) =
  bind print_exc, sys_stderr
  print_exc(self,
    when file is NoneType: sys_stderr
    else: file
  )
