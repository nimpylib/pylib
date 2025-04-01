
import std/macros
import ./[types, prc_cleanup, meth]


macro run*[T: TestCase](self: T) =
  result = newStmtList()
  when not declared(`T.dunder.dict.keys`):
    error "TestCase must be subclassed via `class` pysugar"
  else:
    template call(self, meth): NimNode =
      newCall(bindSym(astToStr(meth)), self)
    result.add call(self, setup)
    for fn in `T.dunder.dict.keys`():
      if fn.startsWith("test_"):
        let fnIdent = ident(fn)
        result.add quote do:
          `fnIdent`(`self`)
    result.add call(self, teardown)

    let doCleanupsId = bindSym("doCleanups")
    result = quote do:
      try:
        `result`
      finally:
        `self`.`doCleanupsId`()
