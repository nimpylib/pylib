
template sleep_neg_raise(s) =
  ## As of 2.1.1, Nim's std/os sleep will deadloop in Windows if `milsecs` is negative.
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
  let currentTime = null;
  do {
    currentTime = new Date().getTime();
  } while (currentTime - start < `milsecs`);
    """.}
template sleep*(s: int) =
  ## raises ValueError if s < 0
  bind sleep, sleep_neg_raise
  sleep_neg_raise(s)
  sleep(milsecs=1000 * s)  # param name based overload
template sleep*(s: float) =
  ## raises ValueError if s < 0
  bind sleep, sleep_neg_raise
  sleep_neg_raise(s)
  sleep(milsecs=int(1000 * s))
