## EXT. stable

import ./private/[exportUtils, errorcodeInit, singleton_errno]
export errorcodeInit, exportAllErrnosViaEnumOrImportc

template prepareRWErrno*{.dirty.} = discard

template prepareROErrno*{.dirty.} =
  prepareRWErrno


template setErrnoRaw*(v: cint) = {.noSideEffect.}:
  bind errno, staticErrno
  when nimvm:
    staticErrno = v
  else:
    errno = v  # as v, for example, ERANGE, is global `let`

template setErrno*(v: untyped) = {.noSideEffect.}:
  bind errno, staticErrno
  when nimvm:
    staticErrno = cint ord Errno.v
  else:
    errno = v  # as v, for example, ERANGE, is global `let`

template setErrno0* = {.noSideEffect.}:
  bind errno, staticErrno
  when nimvm:
    staticErrno = 0
  else:
    errno = 0

proc getErrno*(): cint = {.noSideEffect.}:
  bind errno, staticErrno
  block:
    when nimvm:
      result = staticErrno
    else:
      result = errno

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
