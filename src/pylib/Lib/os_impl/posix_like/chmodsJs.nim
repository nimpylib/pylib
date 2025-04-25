

when defined(js):
  import ../common

  type Mode* = int
  using mode: Mode
  proc chmodImpl(path: cstring, mode){.importDenoOrNodeMod(fs, chmodSync).}
  proc lchmodImpl(path: cstring, mode){.importNode(fs, lchmodSync).}  ## XXX: nodejs: only works on macos
  proc fchmodImpl(fd: int, mode){.importNode(fs, fchmodSync).}
  var chmodExcMsg*: string
  template gen(name; A){.dirty.} =
    proc name*(arg: A, mode: int): cint =
      catchJsErrAsCode(chmodExcMsg, `name Impl`(arg, mode))
  gen chmod, cstring
  gen lchmod, cstring
  gen fchmod, int


