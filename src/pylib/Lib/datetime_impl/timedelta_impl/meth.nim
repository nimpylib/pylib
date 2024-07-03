
import std/times
import std/macros
import std/hashes
from std/math import floorDiv, floorMod, splitDecimal, round
import ./decl

using self: timedelta


func asDuration*(self): Duration =
  ## EXT.
  Duration self
converter cvtDuration(self): Duration = asDuration self

func inMicroseconds(self): int64{.borrow.}

func `==`*(self; o: timedelta): bool =
  self.inMicroseconds == o.inMicroseconds

func timedelta*(days: int64, seconds=0'i64, microseconds=0'i64,
    milliseconds=0'i64, minutes=0'i64, hours=0'i64, weeks=0'i64): timedelta =
  ## timedelta with int-only arguments
  ## 
  ## See `timedelta<#timedelta%2CFI%2CFI%2CFI%2CFI%2CFI%2CFI%2CFI>`_
  ## that accepts mixin float and int as arguments
  ## 
  ## .. hint:: if setting default value for `days`(a.k.a. `days=0`),
  ##   `timedelta()` will fail to be compiled due to `ambiguous call`
  runnableExamples:
    
    template eq(a, b) = assert a == b

    template td(xs: varargs[untyped]): untyped = timedelta(xs)
    # Check keyword args to constructor
    eq(timedelta(), td(weeks=0, days=0, hours=0, minutes=0, seconds=0,
                milliseconds=0, microseconds=0))
    eq(td(1), td(days=1))
    eq(td(0, 1), td(seconds=1))
    eq(td(0, 0, 1), td(microseconds=1))
    eq(td(weeks=1), td(days=7))
    eq(td(days=1), td(hours=24))
    eq(td(hours=1), td(minutes=60))
    eq(td(minutes=1), td(seconds=60))
    eq(td(seconds=1), td(milliseconds=1000))
    eq(td(milliseconds=1), td(microseconds=1000))

  decl.timedelta initDuration(
    days=days, seconds=seconds,
    microseconds=microseconds, milliseconds=milliseconds,
    minutes=minutes, hours=hours,
    weeks=weeks
  )

type
  IntS = int  ## int for sofar
  FactorT = int64
func fromMicroseconds(us: IntS): timedelta =
  decl.timedelta initDuration(microseconds=us)

type FI* = float|int64
func accum(
  sofar: IntS, ## sofar is the # of microseconds accounted for so far
  num: FI,
  factor: FactorT,
  leftover: var float): IntS =
  ##[Fold in the value of the tag ("seconds", "weeks", etc) component of a
  timedelta constructor.  sofar is the # of microseconds accounted for so far,
  and there are factor microseconds per current unit, the number
  of which is given by num.  num * factor is added to sofar in a
  numerically careful way, and that's the result.  Any fractional
  microseconds left over (this can happen if num is a float type) are
  added into `leftover`.
  Note that there are many ways this can give an error (NULL) return.]##
  when num is_not float:
    let prod = num * factor
    result = sofar + prod
  else:
    #[ The Plan:  decompose num into an integer part and a
    fractional part, num = intpart + fracpart.
    Then num * factor == intpart * factor + fracpart * factor
    and the LHS can be computed exactly in long arithmetic.
    The RHS is again broken into an int part and frac part.
    and the frac part is added into *leftover.]#
    var (intpart, fracpart) = num.splitDecimal
    var x = typeof(sofar) intpart
    let prod = x * factor
    let sum = sofar + prod
    if fracpart == 0.0:
      return sum
    #[ So far we've lost no information.  Dealing with the
    fractional part requires float arithmetic, and may
    lose a little info.]#
    let dnum = factor.float * fracpart
    (fracpart, intpart) = dnum.splitDecimal
    x = typeof(sofar) intpart

    result = sum + x
    leftover += fracpart

macro accumByFactors(x: IntS; leftover: float; facs: varargs[untyped]) =
  result = newStmtList()
  for kw in facs:
    let
      key = kw[0]
      val = kw[1]
    result.add quote do:
      if `key` != 0:
        `x` = `x`.accum(`key`, FactorT `val`, `leftover`)

const e6int = 1_000_000

func timedelta*(
    days: FI = 0, seconds: FI = 0, microseconds: FI = 0,
    milliseconds: FI = 0, minutes: FI = 0, hours: FI = 0, weeks: FI = 0): timedelta =
  runnableExamples:
    template eq(a, b) = assert a == b
    template td(xs: varargs[untyped]): untyped = timedelta(xs)
    # from CPython/tests/datetimetester.py
    eq(td(weeks=1.0/7), td(days=1))
    eq(td(days=1.0/24), td(hours=1))
    eq(td(hours=1.0/60), td(minutes=1))
    eq(td(minutes=1.0/60), td(seconds=1))
    eq(td(seconds=0.001), td(milliseconds=1))
    eq(td(milliseconds=0.001), td(microseconds=1))

  var leftover_us = 0.0
  var x: IntS
  x.accumByFactors(leftover_us,
    microseconds = 1,
    milliseconds = 1_000,
    seconds = e6int, 
    minutes = 60 * e6int,
    hours = 3600 * e6int,
    days =  3600 * 24 * e6int,
    weeks = 3600 * 24 * 7 * e6int,
  )
  if leftover_us != 0.0:
    var whole_us = round(leftover_us)

    if abs(whole_us - leftover_us) == 0.5:
      let x_is_odd = float((x and 1) == 1)
      whole_us = 2.0 * round((leftover_us + x_is_odd) * 0.5) - x_is_odd
    
    x += IntS whole_us
  result = x.fromMicroseconds

using _: typedesc[timedelta]

func min*(_): timedelta =
  # .. hint:: not `Duration.low`
  timedelta(days = -999999999)
func max*(_): timedelta =
  timedelta(days=999999999, hours=23, minutes=59,
  seconds=59, microseconds=999999)

func resolution*(_): timedelta =
  timedelta(microseconds=1)

func days*(self): int64 = self.asDuration.inDays

func seconds*(self): int64 =
  self.asDuration.toParts()[Seconds]

func microseconds*(self): int64 =
  self.asDuration.toParts()[Microseconds]

func hash*(self): int =
  let parts = self.asDuration.toParts()
  hash(
    (parts[Days], parts[Seconds], parts[Microseconds])
  )

func repr*(self): string =
  let parts = self.asDuration.toParts()
  template gets(u: FixedTimeUnit): string = $parts[u]
  result = "timedelta(days=" & Days.gets & ", seconds=" & Seconds.gets &
    ", microseconds=" & Microseconds.gets & ')'

func addRepeat(s: var string, c: char, i: int) =
  for _ in 1..i:
    s.add c

func `$`*(self): string =
  ## for timedelta.__str__
  ## 
  ## `[D day[s], ][H]H:MM:SS[.UUUUUU]`, where D is negative for negative t.
  let parts = self.asDuration.toParts()
  template push(s: string; fill=2) =
    let d = fill - s.len
    if d > 0: result.addRepeat '0', d
    result.add s
  template push(u: FixedTimeUnit; fill=2) = push($parts[u], fill)
  let d = parts[Days]
  if d != 0:
    result = $d
    result.add " day"
    if d.abs > 1: result.add 's'
    result.add ", "
  push Hours
  result.add ':'
  push Minutes
  result.add ':'
  push Seconds
  let us = parts[Microseconds]
  if us != 0:
    result.add '.'
    push $us, 6

func total_seconds*(self): float =
  ## timedelta.total_seconds()
  self.inMicroseconds.float / 1e6

template bwBin(op){.dirty.} =
  func op*(a, b: timedelta): timedelta{.borrow.}
bwBin `+`
bwBin `-`

func `*`*(self; i: int64): timedelta{.borrow.}
func `*`*(i: int64, self): timedelta{.borrow.}

template to_even(result) =
    if result > 0: result.inc
    else: result.dec

func is_odd[I](i: I): bool =
  abs(i mod 2) == 1

func divide_nearest[I: SomeInteger](a, b: I): I =
  ## Nearest integer to m / n for integers m and n. Half-integer results
  ## are rounded to even.
  result = a div b
  if b * result != a and
    result.is_odd:
      result.to_even

func divide_nearest[I: SomeInteger; F: SomeFloat](a: I, b: F): I =
  ## Nearest integer to m / n for integers m and n. Half-integer results
  ## are rounded to even.
  let resf = a.F / b
  result = I resf
  if b * resf != a.F and
    result.is_odd:
      result.to_even

func multiply_nearest[I: SomeInteger](a: I, f: float): I =
  ## rounded to even.
  let resf = a.float * f
  result = resf.I
  if result.is_odd:
    if result.float == resf:
      return
    result.to_even
    #result.inc int(result>0)


func `*`*(self; f: float): timedelta =
  fromMicroseconds multiply_nearest(self.inMicroseconds, f)

func `*`*(f: float, self): timedelta = self * f


func `+`*(self): timedelta = self
template bwUnary(op){.dirty.} =
  func op*(self): timedelta{.borrow.}

bwUnary abs

func `-`*(self): timedelta =
  timedelta(-self.days, -self.seconds, -self.microseconds)


func `/`*(self; i: int|float): timedelta =
  timedelta(microseconds=
    divide_nearest(self.inMicroseconds, i)
  )

func `/`*(self; t: timedelta): float =
  self.inMicroseconds / t.inMicroseconds

func `//`*(self; i: int): timedelta =
  fromMicroseconds floorDiv(self.inMicroseconds, i)

func `//`*(self; t: timedelta): int =
  floorDiv self.inMicroseconds, t.inMicroseconds

func `%`*(self, t: timedelta): timedelta =
  fromMicroseconds floorMod(self.inMicroseconds, t.inMicroseconds)

func divmod*(t1, t2: timedelta): (int64, timedelta) =
  let
    us1 = t1.inMicroseconds
    us2 = t2.inMicroseconds
  (floorDiv(us1, us2),
   fromMicroseconds floorMod(us1, us2))

