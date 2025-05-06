
import std/macros
import std/unittest
import std/strutils
import ./[types, prc_cleanup, meth, skips, sig_exc]

proc newTestCall(call, self: NimNode): NimNode =
  #let e = genSym(nskLet, "skipTestExc")
  let e = ident"skipTestExc"
  result = newCall(bindSym"test", newLit call.strVal,
    nnkTryStmt.newTree(
      newCall(call, self),
      nnkExceptBranch.newTree(
        infix(bindSym"SkipTest", "as", e),
        newCall(bindSym"skipTest", self,
          newDotExpr(e, ident"msg")
        )
      )
    )
  )
  ## XXX: FIXME: skip*() now will discard body on if cond is static,
  ##   so such a `test_*` is not defined
  result = quote do:
    when declared(`call`):
      `result`

macro runAux(self; meths: static openArray[string]) =
  result = newStmtList()
  template call(self, meth): NimNode = newCall(bindSym(astToStr(meth)), self)
  result.add call(self, setup)
  for fn in meths:
    if fn.startsWith("test_"):
      let fnIdent = ident(fn)
      result.add newTestCall(fnIdent, self)
  result.add call(self, teardown)

  let doCleanupsId = bindSym("doCleanups")
  result = quote do:
    try:
      `result`
    finally:
      `self`.`doCleanupsId`()

macro methsName(T: static string): untyped = parseExpr('`' & $T & ".dunder.dict.keys()`")

template runImpl(T; self) =
  #when not declared(`T.dunder.dict.keys`): {.error: "TestCase must be subclassed via `class` pysugar, but " & $T & " is not".}
  #else:
    runAux(self, methsName(T))

proc run*[T: TestCase](self: T) =
  bind runImpl
  runImpl($typeof(self), self)
