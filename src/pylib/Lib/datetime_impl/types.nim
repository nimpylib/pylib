##[

.. hint:: Nim's Duration in std/times has the resolution of
  nanoseconds, but Python's timedelta's is microseconds
  But to keep consist with Python, timedelta.resolution is 1 microseconds now.


]##


import std/times

type
  timedelta* = distinct Duration



