import std/locks


test "With statement":
  writeFile("tempfiletest", "just a test")

  with open("tempfiletest", fmRead) as f:
    check f.readLine() == "just a test"

  template open(l: Lock): untyped = l.acquire()
  template close(l: Lock): untyped = l.release()

  var lck: Lock
  lck.initLock()

  with lck:
    check true

  type
    SomeCtxManager = object
      f: File
    SomeOtherManager = object

  proc makeSomeCtxManager(fname: string): SomeCtxManager = 
    SomeCtxManager(f: open(fname, fmRead))

  proc enter(s: SomeCtxManager): File = 
    s.f

  proc exit(s: SomeCtxManager) =
    s.f.close()

  proc open(o: SomeOtherManager): string = 
    result = "Something else"

  proc close(o: SomeOtherManager) = 
    discard

  with makeSomeCtxManager("tempfiletest") as f:
    check f.readAll() == "just a test"

  with SomeOtherManager() as some:
    check some == "Something else"

  # Nested
  with open("tempfiletest", fmRead) as f1:
    with open("tempfiletest", fmRead) as f2:
      check f1.readLine() == f2.readLine() == "just a test"

  var ctx = makeSomeCtxManager("tempfiletest")
  var f = open("tempfiletest", fmRead)
  # Multiple
  with open("tempfiletest", fmRead) as f1, open("tempfiletest", fmRead), 
    makeSomeCtxManager("tempfiletest") as f2, makeSomeCtxManager("tempfiletest"),
    ctx, f:
    check f1.readLine() == f2.readLine() == f.readLine() == "just a test"

  # Discard context manager
  with makeSomeCtxManager("tempfiletest"):
    discard

  # Discard a normal value
  with open("tempfiletest", fmRead):
    discard