##[
  We use origin dtoa.c over Python's
]##

import ../../pyconfig/pycore/pymath

const threads = compileOption("threads")
when threads:
  import std/locks
  var dtoa_locks: array[2, Lock]
  for l in dtoa_locks.mitems:
    l.initLock

  proc ACQUIRE_DTOA_LOCK*(n: c_int){.exportc.} = dtoa_locks[n].acquire()
  proc FREE_DTOA_LOCK*(n: c_int){.exportc.} = dtoa_locks[n].release()
  const threadnoInC = "dtoa_get_threadno"
  proc getThreadId*: c_int{.exportc: threadnoInC.} = c_int system.getThreadId()

const Cflags = block:
  var cflags = ""
  const Dpre = # TODO: use `#define` to C code, maybe there's compiler rejects /D,-D
    when defined(vcc): " /D"
    else: " -D"

  template addD(sym) =
      cflags.add Dpre
      cflags.add astToStr sym
  template define(sym, cond) =
    when cond:
      addD sym

  template defineVal(sym, val) =
    addD sym
    cflags.add "="
    cflags.add val
  template defineVal(sym) = defineVal(sym, astToStr sym)
  
  define MULTIPLE_THREADS, threads
  when threads:
    # need to define ACQUIRE_DTOA_LOCK(n) and FREE_DTOA_LOCK(n) where n is 0 or 1
    defineVal ACQUIRE_DTOA_LOCK
    defineVal FREE_DTOA_LOCK
    defineVal dtoa_get_threadno, threadnoInC

  #[ This code should also work for ARM mixed-endian format on little-endian
    machines, where doubles have byte order 45670123 (in increasing address
    order, 0 being the least significant byte). ]#
  define IEEE_8087, DOUBLE_IS_LITTLE_ENDIAN_IEEE754
  define IEEE_MC68k,  DOUBLE_IS_BIG_ENDIAN_IEEE754 or DOUBLE_IS_ARM_MIXED_ENDIAN_IEEE754
  cflags

{.compile("dtoa-nim.c", Cflags).}

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

