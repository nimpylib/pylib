## c_ldexp

from ./platformUtils import CLike, clikeOr

when CLike:
  {.push header: "<math.h>".}
  proc ldexpf(arg: c_float, exp: c_int): c_float{.importc.}
  proc ldexp(arg: c_double, exp: c_int): c_double{.importc.}
  {.pop.}

import ./patch/ldexp_frexp/ldexp as pure_ldexp

# not very effective, anyway
func n_ldexp*[F: SomeFloat](x: F, i: int): F = F pure_ldexp.ldexp(x.float, i)

#[
func js_ldexp[F: SomeFloat](x: F, i: int): F =
  pure_ldexp.ldexp(x.float, i)
func round_ldexp(x: SomeFloat, i: int): float =
  ## a version of `ldexp`_ that's implemented in pure Nim, used by ldexp in weridTarget
  ##
  ## translated from
  ## https://blog.codefrau.net/2014/08/deconstructing-floats-frexp-and-ldexp.html
  ## which is for JS.
  ## XXX: Not sure if suitable for Obj-C
  let steps = min(3, int ceil(abs(i)/1023) )
  result = x
  for step in 0..<steps:
    result *= pow(2, floor((step+i)/steps))

func n_ldexp[F: SomeFloat](x: F, i: int): F{.used.} =
  when defined(js): js_ldexp(x, i)
  else: round_ldexp(x, i)
]#


func c_ldexp*[F: SomeFloat](x: F, exp: c_int): F =
  clikeOr(
    when x is float32: ldexpf(x.c_float, exp)
    else: ldexp(x.c_double, exp),
    n_ldexp(x, exp)
  )
