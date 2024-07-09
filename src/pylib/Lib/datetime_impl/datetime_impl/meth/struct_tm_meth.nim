
import ./time_t_decl, ./struct_tm_decl

{.push header: "<time.h>".}
when defined(windows):
  proc localtime_s*(tm: var Tm, t: var time_t): cint{.importc.}
  proc gmtime_s*(tm: var Tm, t: var time_t): cint{.importc.}
else:
  proc localtime_r*(t: var time_t, tm: var Tm): ptr Tm{.importc.}
  proc gmtime_r*(t: var time_t, tm: var Tm): ptr Tm{.importc.}
{.pop.}
