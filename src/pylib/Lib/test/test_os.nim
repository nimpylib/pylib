
import ./import_utils
importTestPyLib os

suite "Lib/os":
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
  test "mkdir rmdir":
    const invalidDir = "No one will name such a dir"
    checkpoint "rmdir"
    expect FileNotFoundError:
      os.rmdir(invalidDir)

    checkpoint "mkdir"
    expect FileNotFoundError:
      # parent dir is not found
      os.mkdir(invalidDir + os.sep + "non-file")

  test "get,set_inheritable":
    let fd = os.open(fn, os.O_RDONLY)
    defer: os.close(fd)
    check not os.get_inheritable(fd)

    os.set_inheritable(fd, True)
    check os.get_inheritable(fd)

test "os.path":
  ## only test if os.path is correctly export
  let s = os.path.dirname("1/2")
  check s == "1"
  check os.path.isdir(".")
  assert os.path.join("12", "ab") == str("12") + os.sep + "ab"
