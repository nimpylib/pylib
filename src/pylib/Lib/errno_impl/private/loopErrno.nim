import std/macros
import std/enumutils
import ./clike
import ./errnos

template emitPragma(body: string): NimNode =
  nnkPragma.newTree(
    nnkExprColonExpr.newTree(
      newIdentNode("emit"),
      newLit(body)
    )
  )

template whenDefErrno*(res: NimNode; errnoName: string; body): untyped{.dirty.} =
  bind CLike, add, quote, emitPragma
  when CLike:
    # hint: following takes the responsibility to make declaration of errnoName
    #       to be wrapped by `#ifdef`
    res.add emitPragma "\n#ifdef " & errnoName & '\n'
    body
    res.add emitPragma "\n#endif\n"
  else:
    body

const ErrnoHigh = high(Errno)
template forErrno*(res: NimNode; err; body) =
  bind whenDefErrno, Errno, ErrnoHigh
  for err{.inject.} in succ(Errno.E_SUCCESS)..ErrnoHigh:
    # XXX: NIM-BUG: with `bind Errno` above, use `high(Errno)` here makes Nim
    #  consider Errno as a value instead of a type, thus leading to a warning
    #[Deprecated since v1.4; there should not be `high(value)`. Use `high(type)`.; high is deprecated]#

    #if err == Errno.E_SUCCESS: continue
    result.whenDefErrno symbolName err:
      body
