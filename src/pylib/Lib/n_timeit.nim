## timeit
## 


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

type
  Code = object
    f: proc()

proc newCode(tp: TimeitParam): Code =
  when tp is string:
    {.error: """
here TimeitParam cannot be string,
because Nim is a compile-language, storing code at runtime is impossible,
and implementing compile-time functionality is not worthy""".}
  else:
    result.f = proc() =
      when compiles((let _ = tp())):
        let _ = tp()
      else: tp()

template parseCode(c: Code): untyped =
  c.f()

type
  Timer* = ref object
    timer: typeof(default_timer)
    stmt, setup: Code

proc newTimer*(
    stmt: TimeitParam = NullStmt;
    setup: TimeitParam = NullStmt;
    timer=default_timer, number=default_number): Timer =
  Timer(
    timer: timer,
    stmt: newCode stmt,
    setup: newCode setup,
  )

template timeitImpl(number: int; timer: typed; setupBody, stmtBody): float =
  setupBody
  let started = timer()
  for _ in 1 .. number:
    stmtBody
  timer() - started


template timeit*(self: Timer, number=default_number): float =
  bind timeitImpl, parseCode
  timeitImpl(number, self.timer,
    (parseCode self.setup),
    (parseCode self.stmt)
  )

template timeit*(
    stmt: TimeitParam = NullStmt;
    setup: TimeitParam = NullStmt;
    timer=default_timer, number=default_number): float =
  ## timeit(stmt, setup, number=1000000) with globals is `globals()|locals()`
  ##
  ## stmt, setup are Callable or str literal
  ##
  runnableExamples:
    discard timeit("i.inc", "var i = 0")
    assert i != 0

    proc f() = discard
    discard timeit(f)
    proc retf(): int = 1
    discard timeit(retf)
  bind execTP, timeitImpl
  timeitImpl(number, timer,
    (execTP setup),
    (execTP stmt)
  )


template repeatImpl(repeatExpr: int; doTimeit): seq[float] =
  let repeat = repeatExpr
  var r = newSeq[float](repeat)
  for i in 1..repeat:
    r[i] = doTimeit
  r

template repeat*(
    stmt: TimeitParam = NullStmt;
    setup: TimeitParam = NullStmt;
    timer=default_timer, repeat=default_repeat, number=default_number): seq[float] =
  bind repeatImpl, timeit
  repeatImpl(repeat, timeit(stmt, setup, timer, number))

template repeat*(self: Timer, repeat=default_repeat, number=default_number): seq[float] =
  bind repeatImpl, timeit
  repeatImpl(repeat, timeit(self, number))

template autorange*(self: Timer, callable:
    proc(number: int, time_taken: float) = nil): (int, float) =
  bind timeit
  var i = 1
  var
    number: int
    time_taken: float
  while true:
    for j in [1, 2, 5]:
      number = i * j
      time_taken = timeit(self, number)
      if not callback.isNil:
        callback(number, time_taken)
      if time_taken >= 0.2:
        return (number, time_taken)
    i *= 10

when defined(nimdoc):
  proc print_exc*(self: Timer, file: auto = nil) =
    ## .. hint:: Currently its implementation is based
    ##   on `system.getStackTrace`, which is different from Python's
else:
  when not defined(debug):
    proc print_exc*(self: Timer, file: auto = nil){.error: "only available on debug build".}
  else:
    proc print_exc*(self:Timer, file: auto = nil) =
      when file.isNil:
        writeStackTrace()
      else:
        file.write getStackTrace()
