

import ./errnos
import ./loopErrno
import ./clike
export errnos

import std/enumutils
import std/macros

macro initErrorcodeMap*(K, V; res: untyped, initFunc: typed) =
  mixin `[]=`
  result = newStmtList()
  let N = newLit ErrnoCount
  result.add quote do:
    var `res` = `initFunc`[`K`, `V`](`N`)
  #[
  XXX: NIM-BUG: if using `let` in forErrno loop (in Windows):
  errorcodeInit.nim(18, 7) Error: redefinition of 'errName'; previous declaration here: errorcodeInit.nim(18, 7)
  ]#
  var
    errName: string
    errNameNode, errId: NimNode
  result.forErrno e:
    errName = symbolName e
    errNameNode = newLit errName
    errId = ident errName
    when CLike:
      let addErrnoId = genSym(nskProc, errName)
      # NOTE: just wrap in `res`[`errId`] = `errNameNode` directly in `#ifdef`
      #   doesn't work, as `#ifdef ..  #endif` will not be placed right
      #   around stmt, but
      #   very early in the C file.
      #  so we use a proc.
      result.add quote do:
        proc `addErrnoId`(){.inline.} =
          {.emit: "\n#ifdef " & `errNameNode` & '\n'.}
          `res`[`errId`] = `errNameNode`
          {.emit: "\n#endif\n".}
      result.add newCall(addErrnoId)
    else:
      result.add quote do:
        `res`[`errId`] = `errNameNode`

template declErrorcodeWith*[K, V](initFunc: typed) =
  bind initErrorcodeMap
  initErrorcodeMap K, V,errorcode, initFunc
