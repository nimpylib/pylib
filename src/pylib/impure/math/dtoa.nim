##[
  We use origin dtoa.c over Python's
]##

import ../../builtins/private/pycore_pymath



const Cflags = block:
  var cflags = ""
  template define(sym, cond) =
    when cond:
      cflags.add " -D"
      cflags.add astToStr sym

  #[ TODO: supports threads:on
  const threads = compileOption("threads")
  define MULTIPLE_THREADS, threads
  when threads:
    # need to define ACQUIRE_DTOA_LOCK(n) and FREE_DTOA_LOCK(n) where n is 0 or 1
  ]#

  #[ This code should also work for ARM mixed-endian format on little-endian
    machines, where doubles have byte order 45670123 (in increasing address
    order, 0 being the least significant byte). ]#
  define IEEE_8087, DOUBLE_IS_LITTLE_ENDIAN_IEEE754
  define IEEE_MC68k,  DOUBLE_IS_BIG_ENDIAN_IEEE754 or DOUBLE_IS_ARM_MIXED_ENDIAN_IEEE754
  cflags

{.compile("dtoa.c", Cflags).}

proc dtoa_r*(
    dd: cdouble,
    mode, ndigits: cint,
    decpt, sign: var cint, rve: var cstring,
    buf: cstring; blen: csize_t
): cstring {.importc: "dtoa_r", cdecl, discardable.} ##[ char *
dtoa_r(double dd, int mode, int ndigits, int *decpt, int *sign, char **rve, char *buf, size_t blen)
]##

proc dtoa*(
    d: cdouble,
    mode, ndigits: cint,
    decpt, sign: var cint, rve: var cstring
  ): cstring{.importc: "dtoa", cdecl, discardable.} ##[ char *
dtoa(double d, int mode, int ndigits, int *decpt, int *sign, char **rve)
]##

proc strtod*(
  s00: cstring, se: var cstring
): cdouble{.importc: "strtod", cdecl.} ##[ double
strtod(const char *s00, char **se)
]##

proc strtod*(
  s00: cstring, se: ptr cstring
): cdouble{.importc: "strtod", cdecl.} ## for strtod(s, nil)

proc freedtoa*(s: cstring){.importc, cdecl.}

