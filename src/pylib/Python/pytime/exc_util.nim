
proc time_t_overflow* =
  ## pytime_time_t_overflow
  raise newException(OverflowDefect, "timestamp out of range for platform time_t")
