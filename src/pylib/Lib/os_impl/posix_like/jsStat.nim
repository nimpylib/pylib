
when defined(js):
  import std/jsffi
  from ../common import importNode
  const InNode = defined(nodejs)
  type Stat*#[{.importByNodeOrDeno("require('fs').Stats", "Deno.FileInfo").}]# = JsObject
  using self: Stat
  template impIsXNoNull(isX; isMeth = InNode){.dirty.} =
    ## `is*` is method in NodeJs but attr in Deno.
    ## this can only used for isDirectory, isFile, isSymbolicLink
    ## as their result are non-null.
    proc isX*(self): bool{.importjs:"(#)." & astToStr(isX) & (
      when isMeth: "()" else: ""
    ).}
  impIsXNoNull isDirectory
  impIsXNoNull isFile
  impIsXNoNull isSymbolicLink

  proc statSync*(p: cstring): Stat{.importNode(fs, statSync).}
  proc fstatSync*(fd: cint): Stat{.importNode(fs, fstatSync).}

