
import ./import_utils
importTestPyLib os

suite "Lib/os with no JS support":
  const fn = "tempfiletest"
  test "mkdir rmdir":
    ## XXX: TODO: js's op currently only raises OSError itself
    const invalidDir = "No one will name such a dir"
    checkpoint "rmdir"
    expect FileNotFoundError:
      os.rmdir(invalidDir)

    checkpoint "mkdir"
    expect FileNotFoundError:
      # parent dir is not found
      os.mkdir(invalidDir + os.sep + "non-file")
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