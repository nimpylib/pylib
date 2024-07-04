##[

.. hint:: Nim's Duration in std/times has the resolution of
  nanoseconds, but Python's timedelta's is microseconds
  But to keep consist with Python, timedelta.resolution is 1 microseconds now.


]##

import std/times

type
  timedelta* = ref object
    data: Duration

const TimeDeltaNone*: timedelta = nil

func newTimedelta*(dur: Duration): timedelta = timedelta(data: dur) 

using self: timedelta
func asDuration*(self): Duration =
  ## EXT.
  self.data

func inMicroseconds*(self): int64 = self.data.inMicroseconds

converter toBool*(self): bool =
  self.inMicroseconds == 0
