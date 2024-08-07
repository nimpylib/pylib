## timeit
## 
# status: not completed.

import std/[
  strutils, times, macros
]


const
  default_number* = 1000000
  default_repeat* = 5


proc default_timer_defval(): float{.nimcall.} =
  ## default value of default_timer
  getTime().toUnixFloat

var default_timer* = default_timer_defval

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

type
  NullaryFunc* = concept self ## Callable[[], Any]
    self()
  TimeitParam* = string|NullaryFunc
const NullStmt* = "discard"

template execTP(s: TimeitParam) =
  bind exec
  when compiles((let _ = s())):
    let _ = s()
  elif compiles(s()): s()
  else: exec s

template timeit*(
    stmt: TimeitParam = NullStmt;
    setup: TimeitParam = NullStmt;
    timer=default_timer, number=default_number): float =
  ## timeit(stmt, setup, number=1000000) with globals is `globals()`
  ## 
  ## stmt, setup are Callable or str literal
  ## 
  ## .. hint:: this is equal to python's timeit with arg: `globals=globals()`
  runnableExamples:
    echo timeit("discard")
    proc f() = discard
    discard timeit(f)
    proc retf(): int = 1
    discard timeit(retf)
  bind execTP
  execTP setup
  let started = timer()
  for _ in 1 .. number:
    execTP stmt
  timer() - started

