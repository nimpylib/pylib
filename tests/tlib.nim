
import pylib/Lib/[random]

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
