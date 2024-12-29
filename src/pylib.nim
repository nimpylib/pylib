
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
  macro doc(s: static[string]): untyped = newCommentStmtNode s

  doc "> Welcome to pylib " & Version
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
