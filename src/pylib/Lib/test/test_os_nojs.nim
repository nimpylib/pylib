
import ./import_utils
importTestPyLib os

suite "Lib/os with no JS support":
  const fn = "tempfiletest"
  test "open fdopen close":
    
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

  test "get,set_inheritable":
    let fd = os.open(fn, os.O_RDONLY)
    defer: os.close(fd)
    check not os.get_inheritable(fd)

    os.set_inheritable(fd, True)
    check os.get_inheritable(fd)