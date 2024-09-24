

const CLike* = defined(c) or defined(cpp) or defined(objc)


template prepareRWErrno*{.dirty.} =
  bind CLike
  when CLike:
    var errno{.importc, header: "<errno.h>".}: cint
  else:
    var errno: cint = 0

template prepareROErrno*{.dirty.} =
  bind CLike
  when CLike:
    let errno{.importc, header: "<errno.h>".}: cint
  else:
    let errno: cint = 0

template setErrno*(v: cint) = errno = v
template getErrno*: cint = errno

template isErr*(E: cint): bool =
  bind getErrno
  getErrno() == E

when CLike:
  proc c_strerror(code: cint): cstring{.importc: "strerror", header: "<string.h>".}
  func errnoMsg(errnoCode: cint): string = $c_strerror(errnoCode)
elif defined(js):
  func errnoMsg(errnoCode: cint): string{.warning: "not impl, see how math_patch set error".} = ""

func math_is_error*(x: SomeFloat, exc: var ref Exception): bool =
  prepareROErrno
  result = true  # presumption of guilt
  assert bool errno      # non-zero errno is a precondition for calling
  if isErr EDOM:
    exc = newException(ValueError, "math domain error")
  elif isErr ERANGE:
    #[ ANSI C generally requires libm functions to set ERANGE
      on overflow, but also generally *allows* them to set
      ERANGE on underflow too.  There's no consistency about
      the latter across platforms.
      Alas, C99 never requires that errno be set.
      Here we suppress the underflow errors (libm functions
      should return a zero on underflow, and +- HUGE_VAL on
      overflow, so testing the result for zero suffices to
      distinguish the cases).
      
      On some platforms (Ubuntu/ia64) it seems that errno can be
      set to ERANGE for subnormal results that do *not* underflow
      to zero.  So to be safe, we'll ignore ERANGE whenever the
      function result is less than 1.5 in absolute value.
      
      bpo-46018: Changed to 1.5 to ensure underflows in expm1()
      are correctly detected, since the function may underflow
      toward -1.0 rather than 0.0.
      ]#
    if abs(x) < 1.5:
      result = false
    else:
      exc = newException(OverflowDefect,
                        "math range error")
  else:
    # Unexpected math error
    exc = newException(ValueError, errnoMsg(getErrno()))
