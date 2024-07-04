
import std/strutils
const jsExcludes = "skipJs.txt".slurp.strip().splitLines()

import std/os

var allTests: seq[string]

const SourceDir = currentSourcePath().parentDir

# walkFiles is {.error.} when JS
for t in walkDir(SourceDir):
  if t.kind == pcDir or t.kind == pcLinkToDir: continue
  let name = t.path.lastPathPart
  if name[0] != 't' or name.startsWith "temp": continue
  allTests.add t.path


proc run(backend: string, f: string) =
  let ret = execShellCmd("nim r --backend:$# --hints:off ".format(backend) & f)
  if ret != 0:
    quit ret

echo "Test for C"


for f in allTests:
  run "c", f

echo "Test for JS"

let nodejs = findExe "nodejs"
if nodejs.len == 0:
  echo "warning: no nodejs found, skip JS"
  quit()

for f in allTests:
  if f.lastPathPart not_in jsExcludes:
    run "js", f
