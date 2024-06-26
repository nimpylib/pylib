
import std/times
from std/math import floorDiv, floorMod, splitDecimal, round
import ./types

using self: timedelta


converter asDuration(self): Duration =
  Duration self

func inMicroseconds(self): int64{.borrow.}

func `==`*(self; o: timedelta): bool =
  self.inMicroseconds == o.inMicroseconds

func timedelta*(days=0, seconds=0, microseconds=0,
    milliseconds=0, minutes=0, hours=0, weeks=0): timedelta =
  types.timedelta initDuration(
    days=days, seconds=seconds,
    microseconds=microseconds, milliseconds=milliseconds,
    minutes=minutes, hours=hours,
    weeks=weeks
  )

func fromMicroseconds(us: int64): timedelta =
  types.timedelta initDuration(microseconds=us)

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

