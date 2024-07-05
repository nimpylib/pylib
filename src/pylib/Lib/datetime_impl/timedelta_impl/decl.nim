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

func newTimedelta*(dur: Duration): timedelta = timedelta(data: dur) 

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

func hash*(self): int =
  if self.hashcode == -1:
    self.hashcode = self.hashImpl()
  result = self.hashcode

converter toBool*(self): bool =
  self.inMicroseconds == 0

func `==`*(self; o: timedelta): bool =
  self.inMicroseconds == o.inMicroseconds
