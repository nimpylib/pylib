
import pylib/lib/[tempfile, random]

import std/os

test "tempfile":
  var tname = ""
  const cont = "content"
  with NamedTemporaryFile() as f:
    tname = f.name
    f.write(cont)
    f.flush()
    check fileExists f.name
    f.seek(0)
    check f.read() == cont
  check not fileExists tname

test "random":
  # TODO: more test (maybe firstly set `seed`)
  check randint(1,2) in 1..2
