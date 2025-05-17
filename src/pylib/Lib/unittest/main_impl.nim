
import std/macros
import std/macrocache
import ./case_py/[
  types,
]
const TestCaseSubclasses = CacheSeq"TestCaseSubclasses"

macro init_subclass*[T: TestCase](cls: typedesc[T]) =
  TestCaseSubclasses.add cls

macro main*() =
  result = newStmtList()
  for c in TestCaseSubclasses:
    result.add newCall(
      newDotExpr(
        #ident("new" & c.strVal)
        newCall c
        ,
        ident"run")
    )


