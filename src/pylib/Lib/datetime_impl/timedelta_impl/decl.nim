##[

.. hint:: Nim's Duration in std/times has the resolution of
  nanoseconds, but Python's timedelta's is microseconds
  But to keep consist with Python, timedelta.resolution is 1 microseconds now.


]##

import std/times
import std/hashes

type
  timedelta* = ref object
    data: Duration
    hashcode: int

const TimeDeltaNone*: timedelta = nil
func isTimeDeltaNone*(self: timedelta): bool = self == nil 

func newTimedelta*(dur: Duration): timedelta = timedelta(data: dur) 
func newTimedelta*(days, seconds, microseconds: int,
    normalize = true): timedelta =
  ## CPython's new_delta C-API (private)
  # TODO: opt for normalize == false
  timedelta(data:
    initDuration(days=days, seconds=seconds, microseconds=microseconds))

using self: timedelta
func asDuration*(self): Duration =
  ## EXT.
  self.data

func inMicroseconds*(self): int64 = self.data.inMicroseconds

func hashImpl(self): int =
  let parts = self.asDuration.toParts()
  hash(
    (parts[Days], parts[Seconds], parts[Microseconds])
  )


func flush_hash*(self) =
  ## EXT. calculate hash whatever
  self.hashcode = self.hashImpl()

func hash*(self): int =
  if self.hashcode == -1:
    self.hashcode = self.hashImpl()
  result = self.hashcode

converter toBool*(self): bool =
  self.inMicroseconds == 0

func `==`*(self; o: timedelta): bool =
  # required by datetime_impl/meth
  if self.isTimeDeltaNone and o.isTimeDeltaNone:
    # do not write sth like `self == nil`, it deadloops!
    return true
  self.inMicroseconds == o.inMicroseconds
