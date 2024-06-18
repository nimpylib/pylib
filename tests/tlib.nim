# XXX: While the coverage is rather low,
#  considering many `Lib` of nimpylib are mostly wrapper around Nim's stdlib,
#  we shall mainly focus on the cases where Python differs Nim,
#  and leave the rest to Nim's own stdlib test.

import pylib/Lib/[random, string, math, time]

test "random":
  # TODO: more test (maybe firstly set `seed`)
  check randint(1,2) in 1..2

test "Lib/string":
  check "hello δδ".capwords == "Hello Δδ" ## support Unicode
  check "01234".capwords == "01234"

  let templ = Template("$who likes $what")
  check templ.substitute(who="tim", what="kung pao") == "tim likes kung pao"
  
  expect ValueError:
    let d = dict(who="tim")
    discard templ.substitute(d)

# TODO: more tests.
test "Lib/math":
  checkpoint "log"
  check log(1.0/math.e) == -1
  check log(1.0) == 0
  check log(32.0, 2.0) == 5
  

when not defined(js):
  import pylib/Lib/os
  test "Lib/os":
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

    const invalidDir = "No one will name such a dir"
    checkpoint "rmdir"
    expect FileNotFoundError:
      os.rmdir(invalidDir)

    checkpoint "mkdir"
    expect FileNotFoundError:
      # parent dir is not found
      os.mkdir(invalidDir + os.sep + "non-file")

  test "os.path":
    ## only test if os.path is correctly export
    let s = os.path.dirname("1/2")
    check s == "1"
    check os.path.isdir(".")
    assert os.path.join("12", "ab") == str("12") + os.sep + "ab"

when not defined(js):
  import pylib/Lib/tempfile
  test "Lib/tempfile":
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

test "Lib/time":
  type Self = object
    t: float
  let self = Self(t: time())
  template assertEqual(_: Self; a, b) = check a == b
  checkpoint "test_conversions"

  check int(time.mktime(time.localtime(self.t))) == int(self.t)

  # this function is just getten from CPython/Lib/test/test_time.py
  def test_epoch(self):
    # bpo-43869: Make sure that Python use the same Epoch on all platforms:
    # January 1, 1970, 00:00:00 (UTC).
    epoch = time.gmtime(0)
    # XXX: pylib's struct_time is convertiable to a tuple of 6 members
    # so just test as follows:
    self.assertEqual((1970, 1, 1, 0, 0, 0), epoch)
  
  checkpoint "strftime"
  # the followings as can be run by Python just with one predefinition:
  # def check(b): assert b
  def t_strfptime_date():
    st = strptime("1-6+2024", "%d-%m+%Y")
    def chkEq(fmt, res): check(strftime(fmt, st) == res)
    chkEq("in %Y", "in 2024")
    chkEq("on %b.%d", "on Jun.01")
  t_strfptime_date()

  def t_strfptime_time():
    st = strptime("2:<25:<06", "%S:<%M:<%H")
    def chkEq(fmt, res): check(strftime(fmt, st) == res)
    chkEq("at %H o'clock", "at 06 o'clock")
    chkEq("with %S seconds", "with 02 seconds")
    chkEq("minutes: %M", "minutes: 25")
  t_strfptime_time()

  def t_misc():
    "check date and time, as well as '%%'"
    st = strptime("12:%:2  5$", "%m:%%:%d  %H$")
    def chkEq(fmt, res): check(strftime(fmt, st) == res)
    chkEq("%m %% %d", "12 % 02")
    chkEq("%H hours", "05 hours")
    chkEq("%M", "00")
  t_misc()

