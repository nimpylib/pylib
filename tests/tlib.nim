# XXX: While the coverage is rather low,
#  considering many `Lib` of nimpylib are mostly wrapper around Nim's stdlib,
#  we shall mainly focus on the cases where Python differs Nim,
#  and leave the rest to Nim's own stdlib test.


const dunder_file = currentSourcePath()
when defined(js):

  func restrict_parentDir(s: string): string {.compileTime.}=
    var idx = s.rfind '/'
    if idx == -1: idx = s.rfind '\\' 
    assert idx != -1, "unreachable: not abs path from currentSourcePath()"
    debugEcho  s[0..<idx]
    s[0..<idx]
  func inSourceParentDir(lastPart: string): string{.compileTime.} =
    let sourceDir = dunder_file.restrict_parentDir
    sourceDir & "/../" & lastPart
  ## XXX: when JS and nimvm, parentDir and `/../` cannot work
else:
  func inSourceParentDir(lastPart: string): string{.compileTime.} =
    dunder_file.parentDir /../ lastPart
# NOTE: inSourceParentDir impl is dup in src/pylib/Lib/math_impl/patch/inWordUtilsMapper.nim

const LibTestMain = inSourceParentDir "src/pylib/Lib/test/main.nim"
macro importTestLibMain =
  result = nnkImportStmt.newTree newLit LibTestMain

importTestLibMain()
testAll()

