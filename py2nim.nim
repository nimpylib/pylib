import re, macros, os, strutils

macro multiMatch*(inp: string; sections: varargs[untyped]): untyped =
  ## "Multi regex match". Usage:
  ## multiMatch inp:
  ## of pattern1:
  ##   x = matches[0]
  ## of pattern2:
  ##   ...
  template branch(inp, p, action) =
    var mmlen = matchLen(inp, mmpatterns[p], matches, mmpos)
    if mmlen > 0:
      action
      inc(mmpos, mmlen)
      break searchSubs
  
  template searchLoop(inp, actions) {.dirty} =
    var mmpos = 0
    while mmpos < inp.len:
      block searchSubs:
        actions
        inc(mmpos)
  
  result = newTree(nnkStmtList)
  # first pass: extract regexes:
  var regexes: seq[string] = @[]
  for sec in sections:
    if sec.kind == nnkElse:
      discard
    else:
      expectKind sec, nnkOfBranch
      expectLen sec, 2
      if sec[0].kind in nnkStrLit..nnkTripleStrLit:
        regexes.add sec[0].strVal
      else:
        error("Expected a node of kind nnkStrLit, got " & $sec[0].kind)
  # now generate re-construction and cache regexes for efficiency:
  template declPatterns(size) =
    var mmpatterns{.inject.}: array[size, Regex]
    var matches{.inject.}: array[MaxSubpatterns, string]
  
  template createPattern(i, p) {.dirty.} =
    bind re
    mmpatterns[i] = re(p)
  
  result.add getAst(declPatterns(regexes.len))
  for i, r in regexes:
    result.add getAst(createPattern(i, r))
  
  # last pass: generate code:
  let actions = newTree(nnkStmtList)
  var i = 0
  for sec in sections.children:
    if sec.kind == nnkElse:
      actions.add sec[0]
    else:
      actions.add getAst branch(inp, i, sec[1])
    inc i
  result.add getAst searchLoop(inp, actions)


import sets

proc py2nim(inp: string): string =
  var locals = initSet[string]()
  var globals = initSet[string]()
  result = newStringOfCap(inp.len + 1000)
  result &= "import pylib\n"
  template sink(x) =
    result &= x
  multiMatch inp:
  of r"\b def \s+ (\w+) \(([a-zA-Z0-9_, \t]+)\):":
    sink "proc " & matches[0] & "(" & matches[1] & ": auto): auto ="
    # reset locals:
    locals = initSet[string]()
    globals = initSet[string]()
  of r"(\w+) \s* = \s+":
    if not globals.contains(matches[0]) and not locals.containsOrIncl(matches[0]):
      sink "var "
    sink matches[0] & " = "
  of r"\[\:\]":
    discard
  of r"'(.+)'":
    # Replace ' by "
    sink "\"" & matches[0].replace("\"", "\\\"") & "\""
  of r"\[(.+?):(.+?)\]":
    sink "[" & matches[0] & ".." & matches[0] & "+" & matches[1] & "]"
  #of r"\b print \b":
  #  sink "echo"
  of r"\s*\b global \s+ (\w+);?":
    globals.incl matches[0]
  else:
    sink inp[mmpos]

if paramCount() != 0:
  echo py2nim readFile(paramStr(1))
else:
  echo py2nim stdin.readAll()