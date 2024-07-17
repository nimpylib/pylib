
import ./time_t_decl, ./struct_tm_decl
export time_t_decl, struct_tm_decl
import ./pytime  # nPyTime_localtime, nPyTime_gmtime

proc nTime_localtime*(t: time_t): Tm =
  result.initTm()
  nPyTime_localtime(t, result)

proc nTime_gmtime*(t: time_t): Tm =
  result.initTm()
  nPyTime_gmtime(t, result)
