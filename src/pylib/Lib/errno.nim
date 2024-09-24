
import ./private/errnoUtils
var ord_errno{.compileTime.}: cint = 0

template eno(E) =
  when CLike:
    let E*{.importc, header: "<errno.h>".}: cint
  else:
    let E*: cint = ord_errno
    ord_errno.inc

eno EDOM
eno ERANGE

rwErrno
export errno
