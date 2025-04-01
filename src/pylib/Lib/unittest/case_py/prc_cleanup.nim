
import std/macros
import ./types

macro addCleanup*(self: TestCase; cleanup: proc,
    argsOrKws: varargs[untyped]) =
  let attr = newDotExpr(self, ident("private.cleanups"))
  let cb =
    if argsOrKws.len == 0: cleanup
    else: quote do:
      proc() = `cleanup`(`argsOrKws`)
  result = newCall("add", attr, cb)

proc doCleanups*(self: TestCase) =
  for cleanup in self.`private.cleanups`:
    cleanup()

when isMainModule:
  var self = newTestCase()
  var glb = 0
  self.addCleanup(proc() = glb += 1)
  self.addCleanup(proc(x, y: int) = glb += x+y, 1, y=3)
  assert glb == 0
  self.doCleanups()
  assert glb == 5
