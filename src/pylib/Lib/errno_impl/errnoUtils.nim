## EXT. stable

import ./private/[exportUtils, errorcodeInit, singleton_errno]
export errorcodeInit, exportAllErrnosViaEnumOrImportc

template prepareRWErrno*{.dirty.} = discard

template prepareROErrno*{.dirty.} =
  prepareRWErrno


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

template getErrno*(): cint = {.noSideEffect.}:
  bind errno, staticErrno
  var res: cint
  block:
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
