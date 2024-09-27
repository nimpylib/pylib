

from ./platformUtils import CLike

var staticErrno{.compileTime.}: cint  ## used compile time

when CLike:
  var errno{.importc: "errno", header: "<errno.h>".}: cint
else:
  var errno{.threadvar.}: cint

template prepareRWErrno*{.dirty.} =
  discard

template prepareROErrno*{.dirty.} =
  discard

type Errno*{.pure.} = enum
  EDOM
  ERANGE

template eno(E) =
  when CLike:
    let E*{.importc, header: "<errno.h>".}: cint
  else:
    const E*: cint = cint ord Errno.E

eno EDOM
eno ERANGE

template setErrno*(v: untyped) =
  {.noSideEffect.}:
    when nimvm:
      staticErrno = cint ord Errno.v
    else:
      errno = v  # as v, for example, ERANGE, is global `let`

template setErrno0* =
  {.noSideEffect.}:
    when nimvm:
      staticErrno = 0
    else:
      errno = 0

template getErrno*(): cint =
  var res: cint
  {.noSideEffect.}:
    when nimvm:
      res = staticErrno
    else:
      res = errno
  res

template isErr*(E: untyped): bool =
  bind getErrno
  var c: cint
  {.noSideEffect.}:
    when nimvm:
      c = cint ord Errno.E
    else:
      c = E
  getErrno() == c

template isErr0*(): bool =
  bind getErrno
  getErrno() == 0
