
template sleep_neg_raise(s) =
  # beaware: before Nim#23734, (in 2.1.1),
  # Nim's std/os sleep will deadloop in Windows if `milsecs` is negative.
  if s < 0:
    raise newException(ValueError, "sleep length must be non-negative")
when not defined(js):
  import std/os as nos
else:
  # std/os:
  # Error: this proc is not available on the NimScript/js target
  # usage of 'sleep' is an {.error.}

  # so we define it ourself
  proc sleep(milsecs: int) =
    ## a very urly impl, however,
    ## 
    ## but most of the nodejs's api is for async...
    {.emit:"""
  const start = new Date().getTime();
  let currentTime;
  do {
    currentTime = new Date().getTime();
  } while (currentTime - start < `milsecs`);
    """.}
template sleep*(s: int|float) =
  ## raises ValueError if s < 0
  bind sleep, sleep_neg_raise
  let ss = s  # prevent `s` being eval-ed twice.
  sleep_neg_raise(ss)
  sleep(milsecs=int(1000 * ss))  # param name based overload
