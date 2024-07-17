
import ../time_t_decl
import ../struct_tm_decl
import ./struct_tm_meth
proc nPyTime_localtime*(t: time_t, tm: var Tm) =
  tm = tm_from_local(t)

proc nPyTime_gmtime*(t: time_t, tm: var Tm) =
  tm = tm_from_utc(t)
