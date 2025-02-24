
import std/macros

const nimDoc = defined(nimdoc)
macro platformAvailImpl(inPlat: static[bool]; platStr: static[string]; def) =
  if nimDoc:
    def.body = newStmtList(
      newCommentStmtNode ".. hint:: `Availability" &
        "<https://docs.python.org/3/library/intro.html#availability>`_: " &
          platStr,
      nnkDiscardStmt.newTree newEmptyNode()
    )
    return def
  if inPlat:
    return def
  result = def
  result.body = newEmptyNode()
  result.addPragma newColonExpr(
    ident"error",
    newLit "this is only available on platform: " & platStr & '.'
  )

template platformAvail*(platform; def) =
  ## Pragma on procs to generate doc of sth like `Availability: Windows.`
  ##
  ## Currently, `platform` must be something
  ## that can be put within `defined`.
  bind platformAvailImpl
  platformAvailImpl(defined(platform), astToStr(platform), def)

template platformAvailWhen*(platform; cond: static[bool]; def) =
  bind platformAvailImpl
  platformAvailImpl(defined(platform) and cond,
    astToStr(platform) & " when " & astToStr(cond), def)
