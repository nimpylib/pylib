## .. include:: ../doc/pylib.md
when defined(nimHasStrictFuncs):
  {.experimental: "strictFuncs".}

import std/[
  strutils, times  # only used for timeit
]

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

template timeit*(repetitions: int, statements: untyped): untyped =
  ## Mimics Pythons ``timeit.timeit()``, output shows more information than Pythons.
  bind times.`$`
  template cpuTimeImpl(): untyped =
    when defined(js): now() else: cpuTime()
  let
    started = now()
    cpuStarted = cpuTimeImpl()
  for i in 0 .. repetitions:
    statements
  echo "$1 TimeIt: $2 Repetitions on $3, CPU Time $4.".format(
    $now(), repetitions, $(now() - started), $(cpuTimeImpl() - cpuStarted))
