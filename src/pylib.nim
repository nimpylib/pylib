
const WarnLeniOps = "`std/lenientops` was imported automatically. " &
  "Compile with -d:pylibNoLenient to disable it " &
  "if you wish to do int->float conversions yourself"

when not defined(pylibNoLenient):
  {.warning: WarnLeniOps.}
  import std/lenientops
  export lenientops

when defined(nimdoc):
  from pylib/version import Version
  import std/macros
  import std/strformat
  import std/strutils
  macro doc(s: static[string]): untyped = newCommentStmtNode s

  template hs(s): string = "https://" & s
  const
    RepoUrl = hs"github.com/nimpylib/pylib"
    ReadmeUrl = RepoUrl & "?tab=readme-ov-file#nimpylib"
    WikiUrl = RepoUrl & "/wiki"
  template link(name, url: string): string = "[" & name & "](" & url & ")"

  const
    homepage{.strdefine.} = hs"nimpylib.github.io/pylib"
  func stripDoc(s: string): string =
    result = s
    var proto: string
    const sep = "://"
    let ls = s.split(sep, 1)
    (proto, result) = (ls[0], ls[1])
    result.removePrefix"docs."
    result = proto & sep & result

  doc "> Welcome to **NimPyLib** :sub:`" & Version & "`"  # Nim's Markdown is RST-extended
  doc fmt"""- link to {link("repo", ReadmeUrl)}, {link("wiki", WikiUrl)}, """ &
   link("home", stripDoc homepage)
  ## .. include:: ../doc/pylib.md
  doc ".. warning:: " & WarnLeniOps

import pylib/Lib/timeit

when not defined(js) and not defined(nimscript):
  import pylib/io
  export io
import pylib/private/trans_imp

impExp pylib,
  noneType, pybool, builtins,
  ops, pyerrors,
  pystring, pybytes, pybytearray,
  pysugar


template timeit*(repetitions: int, statements: untyped): untyped{.deprecated:
    "will be removed from main pylib since 0.10, import it from `pylib/Lib` instead".} =
  ## EXT.
  ## 
  ## Mimics Pythons ``timeit.timeit()``, output shows more information than Pythons.
  bind timeit
  timeit(repetitions):
    statements
