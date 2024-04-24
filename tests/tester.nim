import std/macros
import std/os as nos
from std/strutils import splitLines, strip, endsWith

import pylib

when defined(js):
  const jsExclude = """
iters
list
io
""".strip(leading=false, chars={'\n'}).splitLines()

import std/unittest

func mySplitFile(path: string): tuple[dir, last: string] =
  # if JS on Windows, DirSep is '/'
  # As a result:
  # - os.parentDir() results in `.`
  # - lastPathPart() results in origin args
  let ls = strutils.rsplit(path, {DirSep, AltSep, '\\'}, 1)
  (ls[0], ls[1])

macro gen =
  result = newNimNode nnkIncludeStmt
  let thisFile = currentSourcePath()
  let thisDir = mySplitFile(thisFile)[0] #parentDir
  for de in walkDir(thisDir):
    if de.kind == pcDir:
      continue
    let fp = de.path
    let fn = fp.mySplitFile()[1]  #lastPathPart
    if fp == thisFile: continue  # avoid self-inclusion
    if fn[0] == 't' and fn.endswith ".nim":
      when defined(js):
        let pureName = fn[1 ..< ^len".nim"]
        if pureName in jsExclude:
          continue
      result.add newLit fp
  #echo result.repr

gen()
