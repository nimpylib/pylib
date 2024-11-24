
import ./errnos
export errnos

import std/macros

import std/enumutils

template eno(E) =
  when CLike:
    let E*{.importc, header: "<errno.h>".}: cint
  else:
    const E*: cint = cint ord Errno.E

macro exportEnumOrImportc*() =
  result = newStmtList()
  for e in Errno:
    result.add newCall(bindSym"eno", ident symbolName e)    



