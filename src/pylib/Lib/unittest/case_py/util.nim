import std/macros
import ./types

macro genSelf*(templ) =
  result = newStmtList()
  result.add templ
  var nTempl = copyNimTree templ
  nTempl.params.insert 1, newIdentDefs(ident"self", bindSym"TestCase")
  result.add nTempl
