## .. include:: ../doc/pylib.md

import pylib/Lib/timeit

when not defined(js):
  import pylib/io
  export io
import pylib/private/trans_imp

impExp pylib,
  noneType, pybool, builtins,
  numTypes, ops,
  pystring, pybytes, pybytearray,
  pysugar

when not defined(pylibNoLenient):
  {.warning: "'lenientops' module was imported automatically. Compile with -d:pylibNoLenient to disable it if you wish to do int->float conversions yourself".}
  import std/lenientops
  export lenientops

template timeit*(repetitions: int, statements: untyped): untyped{.deprecated:
    "will be removed from main pylib since 0.10, import it from `pylib/Lib` instead".} =
  ## EXT.
  ## 
  ## Mimics Pythons ``timeit.timeit()``, output shows more information than Pythons.
  bind timeit
  timeit(repetitions):
    statements
