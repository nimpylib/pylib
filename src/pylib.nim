
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
  macro doc(s: static[string]): untyped = newCommentStmtNode s

  const
    RepoUrl = "https://github.com/nimpylib/pylib"
    ReadmeUrl = RepoUrl & "?tab=readme-ov-file#nimpylib"
    WikiUrl = RepoUrl & "/wiki"
  template link(name, url: string): string = "[" & name & "](" & url & ")"

  doc "> Welcome to **NimPyLib** :sub:`" & Version & "`"  # Nim's Markdown is RST-extended
  doc fmt"""- link to {link("repo", ReadmeUrl)}, {link("wiki", WikiUrl)}"""
  ## .. include:: ../doc/pylib.md
  doc ".. warning:: " & WarnLeniOps

import pylib/Lib/timeit

when not defined(js) and not defined(nimscript):
  import pylib/io
  export io
import pylib/private/trans_imp

impExp pylib,
  noneType, pybool, builtins,
  numTypes, ops, pyerrors,
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
