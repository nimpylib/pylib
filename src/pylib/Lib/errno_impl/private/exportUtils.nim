
import ./clike
import ./loopErrno
import ./errnos
export errnos

import std/macros

import std/enumutils

template eno(E) =
  when CLike:
    let E*{.importc, header: "<errno.h>".}: cint
  else:
    const E*: cint = cint ord Errno.E

macro exportAllErrnosViaEnumOrImportc*() =
  result = newStmtList()
  forErrno e:
    result.add newCall(bindSym"eno", ident symbolName e)    



