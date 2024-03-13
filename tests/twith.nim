import std/locks
import std/streams

test "With statement":
  let cont = "just a test"
  template newStream(): untyped = newStringStream(cont)

  with newStream() as f:
    check f.readLine() == "just a test"

  template open(l: Lock): untyped = l.acquire()
  template close(l: Lock): untyped = l.release()

  var lck: Lock
  lck.initLock()

  with lck:
    check true

  type
    SomeCtxManager = object
      f: Stream
    SomeOtherManager = object

  proc makeSomeCtxManager(): SomeCtxManager = 
    SomeCtxManager(f: newStream())

  proc enter(s: SomeCtxManager): Stream = 
    s.f

  proc exit(s: SomeCtxManager) =
    s.f.close()

  proc open(o: SomeOtherManager): string = 
    result = "Something else"

  proc close(o: SomeOtherManager) = 
    discard

  with makeSomeCtxManager() as f:
    check f.readAll() == "just a test"

  with SomeOtherManager() as some:
    check some == "Something else"

  # Nested
  with newStream() as f1:
    with newStream() as f2:
      check f1.readLine() == f2.readLine() == "just a test"

  var ctx = makeSomeCtxManager()
  var f = newStream()
  # Multiple
  with newStream() as f1, newStream(), 
    newStream() as f2, makeSomeCtxManager(),
    ctx, f:
    check f1.readLine() == f2.readLine() == f.readLine() == "just a test"

  # Discard context manager
  with makeSomeCtxManager():
    discard

  # Discard a normal value
  with newStream():
    discard