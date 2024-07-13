
import ./import_utils
importTestPyLib datetime

let
  ZERO = timedelta(0)
  MINUTE = timedelta(minutes=1)
  HOUR = timedelta(hours=1)
  DAY = timedelta(days=1)
  DT = datetime(1970, 1, 1)

template assertEqual(a, b) = check a == b

suite "datetime":
  test "utcoffset":
    def test_utcoffset():
      dummy = DT
      for h in [0.0, 1.5, 12.0]:
          offset = h * HOUR
          assertEqual(offset, timezone(offset).utcoffset(dummy))
          assertEqual(-offset, timezone(-offset).utcoffset(dummy))
    test_utcoffset()

  test "attrs":
    def test_trivial():
      dt = datetime(1, 2, 3, 4, 5, 6, 7)
      assertEqual(dt.year, 1)
      assertEqual(dt.month, 2)
      assertEqual(dt.day, 3)
      assertEqual(dt.hour, 4)
      assertEqual(dt.minute, 5)
      assertEqual(dt.second, 6)
      assertEqual(dt.microsecond, 7)
      assertEqual(dt.tzinfo, None)
    test_trivial()
  
  test "isoformat":
    let t = datetime(1, 2, 3, 4, 5, 1, 123)
    assertEqual(t.isoformat(),    "0001-02-03T04:05:01.000123")
    assertEqual(t.isoformat("T"), "0001-02-03T04:05:01.000123")
    assertEqual(t.isoformat(" "), "0001-02-03 04:05:01.000123")
    assertEqual(t.isoformat("\x00"), "0001-02-03\x0004:05:01.000123")
    # bpo-34482: Check that surrogates are handled properly.
    assertEqual(t.isoformat("\ud800"),
                      "0001-02-03\ud80004:05:01.000123")
    assertEqual(t.isoformat(timespec="hours"), "0001-02-03T04")
    assertEqual(t.isoformat(timespec="minutes"), "0001-02-03T04:05")
    assertEqual(t.isoformat(timespec="seconds"), "0001-02-03T04:05:01")
    assertEqual(t.isoformat(timespec="milliseconds"), "0001-02-03T04:05:01.000")
    assertEqual(t.isoformat(timespec="microseconds"), "0001-02-03T04:05:01.000123")
    assertEqual(t.isoformat(timespec="auto"), "0001-02-03T04:05:01.000123")
    assertEqual(t.isoformat(sep=" ", timespec="minutes"), "0001-02-03 04:05")
    expect(ValueError):
      discard t.isoformat(timespec="foo")
    # bpo-34482: Check that surrogates are handled properly.
    expect(ValueError):
      discard t.isoformat(timespec="\ud800")
    # str is ISO format with the separator forced to a blank.
    assertEqual(str(t), "0001-02-03 04:05:01.000123")

class FixedOffset(tzinfo):
    offset: timedelta
    name: PyStr
    dstoffset: timedelta
    def init(self, offset: int, name, dstoffset=42):
        offset = timedelta(days=0, minutes=offset)
        dstoffset = timedelta(days=0, minutes=dstoffset)
        self.offset = offset
        self.name = name
        self.dstoffset = dstoffset
    def repr(self):
        return self.name.lower()
    def utcoffset(self, dt: datetime):
        return self.offset
    def tzname(self, dt: datetime):
        return self.name
    def dst(self, dt: datetime):
        return self.dstoffset

suite "timedelta":
  test "init":
    template eq(a, b) = check a == b

    # Check keyword args to constructor
    eq(timedelta(1), timedelta(days=1))
    eq(timedelta(0, 1), timedelta(seconds=1))
    eq(timedelta(0, 0, 1), timedelta(microseconds=1))
    eq(timedelta(weeks=1), timedelta(days=7))
    eq(timedelta(days=1), timedelta(hours=24))
    eq(timedelta(hours=1), timedelta(minutes=60))
    eq(timedelta(minutes=1), timedelta(seconds=60))
    eq(timedelta(seconds=1), timedelta(milliseconds=1000))
    eq(timedelta(milliseconds=1), timedelta(microseconds=1000))

  test "float init":
    template eq(a, b) = check a == b
    # from CPython/tests/datetimetester.py
    eq(timedelta(weeks=1.0/7), timedelta(days=1))
    eq(timedelta(days=1.0/24), timedelta(hours=1))
    eq(timedelta(hours=1.0/60), timedelta(minutes=1))
    eq(timedelta(minutes=1.0/60), timedelta(seconds=1))
    eq(timedelta(seconds=0.001), timedelta(milliseconds=1))
    eq(timedelta(milliseconds=0.001), timedelta(microseconds=1))

  test "normalize":
    proc tG(delta: timedelta, days, seconds, microseconds: int64) =
      check delta.days == days
      check delta.seconds == seconds
      check delta.microseconds == microseconds
    tG timedelta(microseconds = -1), -1, 86399, 999999
    tG timedelta(days = -1, hours = -1, seconds = -59, microseconds = -1),
        days = -2, seconds=82740, microseconds=999999
    tG timedelta(days = -2, hours = -3, seconds = -4559, microseconds = -5),
        days = -3, seconds=71040, microseconds=999995
    tG timedelta(days = 2, hours = -3, seconds = -4, microseconds = -5),
        days=1, seconds=75595, microseconds=999995
    

import std/macros
suite "date":
  template theclass: untyped = PyDatetime
  template theclass(x: untyped, xs: varargs[untyped]): untyped =
    init.datetime(x, xs)
  test "fromisocalendar":
    def test_fromisocalendar():
        # For each test case, assert that fromisocalendar is the
        # inverse of the isocalendar function
        dates = [
            (2016, 4, 3),
            (2005, 1, 2),       # (2004, 53, 7)
            (2008, 12, 30),     # (2009, 1, 2)
            (2010, 1, 2),       # (2009, 53, 6)
            (2009, 12, 31),     # (2009, 53, 4)
            (1900, 1, 1),       # Unusual non-leap year (year % 100 == 0)
            (1900, 12, 31),
            (2000, 1, 1),       # Unusual leap year (year % 400 == 0)
            (2000, 12, 31),
            (2004, 1, 1),       # Leap year
            (2004, 12, 31),
            (1, 1, 1),
            (9999, 12, 31),
            (MINYEAR, 1, 1),
            (MAXYEAR, 12, 31),
        ]

        for datecomps in dates:
            dobj = theclass(datecomps[0], datecomps[1], datecomps[2])
            isocal = dobj.isocalendar()

            d_roundtrip = theclass.fromisocalendar(isocal[0], isocal[1], isocal[2])

            assertEqual(dobj, d_roundtrip)
    test_fromisocalendar()

  test "fromisocalendar_value_errors":
    def test_fromisocalendar_value_errors():
        isocals = [
            (2019, 0, 1),
            (2019, -1, 1),
            (2019, 54, 1),
            (2019, 1, 0),
            (2019, 1, -1),
            (2019, 1, 8),
            (2019, 53, 1),
            (10000, 1, 1),
            (0, 1, 1),
            (9999999, 1, 1),
            (2<<32, 1, 1),
            (2019, 2<<32, 1),
            (2019, 1, 2<<32),
        ]

        for isocal in isocals:
            expect(ValueError):
                _ = PyDatetime.fromisocalendar(isocal[0], isocal[1], isocal[2])
    test_fromisocalendar_value_errors()

  test "ordinal_conversion":
    def test_ordinal_conversions():
        # Check some fixed values.
        for tup in [(1, 1, 1, 1),      # calendar origin
                      (1, 12, 31, 365),
                      (2, 1, 1, 366),
                      # first example from "Calendrical Calculations"
                      (1945, 11, 12, 710347)]:
            (y, m, day, n) = tup
            d = theclass(y, m, day)
            assertEqual(n, d.toordinal())
            fromord = theclass.fromordinal(n)
            assertEqual(d, fromord)
            if hasattr(fromord, "hour"):
            # if we're checking something fancier than a date, verify
            # the extra fields have been zeroed out
                assertEqual(fromord.hour, 0)
                assertEqual(fromord.minute, 0)
                assertEqual(fromord.second, 0)
                assertEqual(fromord.microsecond, 0)

        # Check first and last days of year spottily across the whole
        # range of years supported.
        for year in range(MINYEAR, MAXYEAR+1, 7):
            # Verify (year, 1, 1) -> ordinal -> y, m, d is identity.
            d1 = theclass(year, 1, 1)
            n1 = d1.toordinal()
            d2 = theclass.fromordinal(n1)
            assertEqual(d1, d2)
            # Verify that moving back a day gets to the end of year-1.
            if year > 1:
                d1 = theclass.fromordinal(n1-1)
                d2 = theclass(year-1, 12, 31)
                assertEqual(d1, d2)
                assertEqual(d2.toordinal(), n1-1)

        # Test every day in a leap-year and a non-leap year.
        dim = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        for (year, isleap) in [(2000, True), (2002, False)]:
            n2 = theclass(year, 1, 1).toordinal()
            for month, rmaxday in zip(range(1, 13), dim):
                maxday = rmaxday
                if month == 2 and isleap:
                    maxday += 1
                for day in range(1, maxday+1):
                    d3 = theclass(year, month, day)
                    assertEqual(d3.toordinal(), n2)
                    assertEqual(d3, theclass.fromordinal(n2))
                    n2 += 1
    test_ordinal_conversions()

  test "replace":
    macro replaceWith(dt: datetime, name: static string, x): datetime =
      let nameId = ident name
      result = quote do:
        `dt`.replace(`nameId`=`x`)
    const
      changes = [("year", 2),
                  ("month", 3),
                  ("day", 4)]
      args = [1, 2, 3]
    macro test_replaceWith(base: datetime) =
        result = newStmtList()
        var i = 0
        for (name, newval) in changes:
          let iD = newLit i
          let
            nameId = newLit name
            newvalId = newLit newval
          result.add quote do:
            block:
              var newargs = args
              newargs[`iD`] = `newvalId`
              let expected = theclass(newargs[0], newargs[1], newargs[2])
              assertEqual(replaceWith(`base`, `nameId`, `newvalId`), expected)
          i += 1

    def test_replace():
        base = theclass(args[0], args[1], args[2])
        assertEqual(base.replace(), base)

        test_replaceWith base
        
        # Out of bounds.
        base = theclass(2000, 2, 29)
        expect(ValueError):
          _ = base.replace(year=2001)
    test_replace()

  test "strftime":
    def test_strftime():
        t = theclass(2005, 3, 2)
        assertEqual(t.strftime("m:%m d:%d y:%Y"), "m:03 d:02 y:2005")
        assertEqual(t.strftime(""), "") # SF bug #761337
        assertEqual(t.strftime('x'*1000), 'x'*1000) # SF bug #1556784

        check not compiles(t.strftime) # needs an arg
        check not compiles(t.strftime("one", "two")) # too many args
        check not compiles(t.strftime(42)) # arg wrong type

        # test that unicode input is allowed (issue 2782)
        assertEqual(t.strftime("%m"), "03")

        # A naive object replaces %z, %:z and %Z w/ empty strings.
        assertEqual(t.strftime("'%z' '%:z' '%Z'"), "'' '' ''")
    test_strftime()
  test "ctime":
    let t = theclass(2002, 3, 2)
    assertEqual(t.ctime(), "Sat Mar  2 00:00:00 2002")

importPyLib time
suite "tzinfo":
  test "fromtimestamp":
    template meth(xs: varargs[untyped]): datetime =
      datetime.PyDatetime.fromtimestamp(xs)
    def test_tzinfo_fromtimestamp():
      ts = time.time()
      # Ensure it doesn't require tzinfo (i.e., that this doesn't blow up).
      base = meth(ts)
      # Try with and without naming the keyword.
      off42 = newFixedOffset(42, "42")
      another = meth(ts, off42)
      again = meth(ts, tz=off42)
      #assertIs(another.tzinfo, again.tzinfo)
      assertEqual(another.utcoffset(), timedelta(minutes=42))
    test_tzinfo_fromtimestamp()
