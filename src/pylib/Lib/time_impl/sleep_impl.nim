
import ../sys_impl/auditImpl as sys
proc sleep_neg_raise_or2ms(s: int|float): int =
  # beaware: before Nim#23734, (in 2.1.1),
  # Nim's std/os sleep will deadloop in Windows if `milsecs` is negative.
  if s < 0:
    raise newException(ValueError, "sleep length must be non-negative")
  let ms = s*1000
  when s is float: int(ms+0.5)
  else: ms

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
  var __nimpylib_temp_waitTill = new Date(new Date().getTime() + `milsecs`);
  while (__nimpylib_temp_waitTill >= new Date()){}
    """.}
template sleep*(s: int|float) =
  ## raises ValueError if s < 0
  bind sleep, sleep_neg_raise_or2ms, audit
  sys.audit("time.sleep", s)
  # also prevent `s` being eval-ed twice.
  let ms = sleep_neg_raise_or2ms(s)
  sleep(milsecs=ms)  # param name based overload
