
import std/macros
import std/macrocache
import ./case_py/[
  types,
]
const TestCaseSubclasses = CacheSeq"TestCaseSubclasses"

macro init_subclass*[T: TestCase](cls: typedesc[T]) =
  TestCaseSubclasses.add(
    if cls.kind == nnkTypeOfExpr: cls[0]
    else: cls
  )

macro main*() =
  result = newStmtList()
  for c in TestCaseSubclasses:
    result.add newCall(
      newDotExpr(
        newCall ident("new" & c.strVal)
        #nnkObjConstr.newTree c
        ,
        ident"run")
    )


