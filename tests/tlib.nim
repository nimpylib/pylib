# XXX: While the coverage is rather low,
#  considering many `Lib` of nimpylib are mostly wrapper around Nim's stdlib,
#  we shall mainly focus on the cases where Python differs Nim,
#  and leave the rest to Nim's own stdlib test.

import pylib/Lib/[random, string, math]

test "random":
  # TODO: more test (maybe firstly set `seed`)
  check randint(1,2) in 1..2

test "Lib/string":
  check "hello δδ".capwords == "Hello Δδ" ## support Unicode
  check "01234".capwords == "01234"

# TODO: more tests.
test "Lib/math":
  checkpoint "log"
  check log(1.0/math.e) == -1
  check log(1.0) == 0
  check log(32.0, 2.0) == 5
  

when not defined(js):
  import pylib/Lib/os
  test "os":
    const fn = "tempfiletest"
    template open(fd: int, s: string): untyped{.used.} =  # this won't be called
      doAssert false
      io.open(fd, s)
    let fd = open(fn, O_RDWR|O_CREAT)
    var f = fdopen(fd, "w+")
    let s = "123"
    f.write(s)
    f.seek(0)
    let res = f.read()
    f.close()
    check res == s

  test "os.path":
    ## only test if os.path is correctly export
    let s = os.path.dirname("1/2")
    check s == "1"
    check os.path.isdir(".")

when not defined(js):
  import pylib/Lib/tempfile
  test "tempfile":
    var tname = ""
    const cont = b"content"
    with NamedTemporaryFile() as f:  # open in binary mode by default
      tname = f.name
      f.write(cont)
      f.flush()
      check fileExists f.name
      f.seek(0)
      check f.read() == cont
    check not fileExists tname

