## timeit
## 
# status: not completed.

import std/[
  strutils, times, macros
]

template cpuTimeImpl(): untyped =
  when defined(js): now() else: cpuTime()

template timeit*(repetitions: int, statements: untyped) =
  ## EXT.
  ## unstable.
  ## 
  ## returns nothing but send output to stdout.
  ## 
  ## output shows more information than Pythons.
  runnableExamples:
    var i = 0
    timeit(10):
      i.inc
    assert i == 10
  bind times.`$`, times.`-`, now, format, cpuTimeImpl
  let
    started = now()
    cpuStarted = cpuTimeImpl()
  for _ in 1 .. repetitions:
    statements
  echo "$1 TimeIt: $2 Repetitions on $3, CPU Time $4.".format(
    $now(), repetitions, $(now() - started), $(cpuTimeImpl() - cpuStarted))

macro exec(s: static[string]) = parseStmt s

template timeit*(stmt; setup; number=1000000): float =
  ## timeit(stmt, setup, number=1000000) with globals is `globals()`
  ## 
  ## stmt, setup are Callable or str literal
  ## 
  ## .. hint:: this is equal to python's timeit with arg: `globals=globals()`
  bind times.`$`, times.`-`, now, format, inNanoseconds, exec

  when compiles(setup()): setup()
  else: exec setup
  let started = now()
  for _ in 1 .. number:
    when compiles(stmt()): stmt()
    else: exec stmt
  let delta = now() - started

  inNanoseconds(delta).float / 1e9

template timeit*(stmt; number=1000000): float =
  runnableExamples:
    echo timeit("discard")
  bind timeit
  timeit(stmt, "", number)


template timeit*(number=1000000): float = 
  bind timeit
  timeit("", "", number)
