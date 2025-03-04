
import ./import_utils
importTestPyLib time

test "Lib/time":
  checkpoint "struct_time.__repr__"
  check str(gmtime(0)) == "time.struct_time(tm_year=1970, tm_mon=1, tm_mday=1, tm_hour=0, tm_min=0, tm_sec=0, tm_wday=3, tm_yday=1, tm_isdst=0)"
  type Self = object
    t: float
  let self = Self(t: time())

  checkpoint "test_conversions"

  check int(time.mktime(time.localtime(self.t))) == int(self.t)

  check gmtime(0) == gmtime(0)
  
  checkpoint "strftime"
  # the followings as can be run by Python just with one predefinition:
  # def check(b): assert b
  def chkEq(st, fmt, res): check(strftime(fmt, st) == res)

  def t_strfptime_date():
    st = strptime("1-6+2024", "%d-%m+%Y")
    chkEq(st, "in %Y", "in 2024")
    chkEq(st, "on %b.%d", "on Jun.01")
  t_strfptime_date()

  def t_strfptime_time():
    st = strptime("2:<25:<06", "%S:<%M:<%H")
    chkEq(st, "at %H o'clock", "at 06 o'clock")
    chkEq(st, "with %S seconds", "with 02 seconds")
    chkEq(st, "minutes: %M", "minutes: 25")
  t_strfptime_time()

  def t_misc():
    "check date and time, as well as '%%'"
    st = strptime("12:%:2  5$", "%m:%%:%d  %H$")
    chkEq(st, "%m %% %d", "12 % 02")
    chkEq(st, "%H hours", "05 hours")
    chkEq(st, "%M", "00")
  t_misc()