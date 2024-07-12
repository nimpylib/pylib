
import ./import_utils
importTestPyLib datetime

let
  ZERO = timedelta(0)
  MINUTE = timedelta(minutes=1)
  HOUR = timedelta(hours=1)
  DAY = timedelta(days=1)
  DT = datetime(1970, 1, 1)

test "timedelta init":
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

test "timedelta float init":
  template eq(a, b) = check a == b
  # from CPython/tests/datetimetester.py
  eq(timedelta(weeks=1.0/7), timedelta(days=1))
  eq(timedelta(days=1.0/24), timedelta(hours=1))
  eq(timedelta(hours=1.0/60), timedelta(minutes=1))
  eq(timedelta(minutes=1.0/60), timedelta(seconds=1))
  eq(timedelta(seconds=0.001), timedelta(milliseconds=1))
  eq(timedelta(milliseconds=0.001), timedelta(microseconds=1))

template assertEqual(a, b) = check a == b
test "datetime.utcoffset":
  def test_utcoffset():
    dummy = DT
    for h in [0.0, 1.5, 12.0]:
        offset = h * HOUR
        assertEqual(offset, timezone(offset).utcoffset(dummy))
        assertEqual(-offset, timezone(-offset).utcoffset(dummy))
  test_utcoffset()

test "datetime attrs":
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

class FixedOffset(tzinfo):
    offset: timedelta
    name: PyStr
    dstoffset: timedelta
    def init(self, offset: int, name, dstoffset=42):
        offset = timedelta(minutes=offset)
        dstoffset = timedelta(minutes=dstoffset)
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

importPyLib time
test "tzinfo fromtimestamp":
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

suite "TestTimedelta":

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
suite "TestDate":
  template theclass: untyped = PyDatetime
  template theclass(x: untyped, xs: varargs[untyped]): untyped =
    datetime(x, xs)
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
    macro replaceWith(dt: datetime, name: string, x): datetime =
      let nameId = newLit name
      result = quote do:
        `dt`.replace(`nameId`=`x`)
    def test_replace(self):
        args = [1, 2, 3]
        base = theclass(args[0], arg[1], arg[2])
        assertEqual(base.replace(), base)
        assertEqual(copy.replace(base), base)

        changes = (("year", 2),
                   ("month", 3),
                   ("day", 4))
        for i, (name, newval) in enumerate(changes):
            newargs = list(args)
            newargs[i] = newval
            expected = theclass(newargs[0], newargs[1], newargs[2])
            assertEqual(replaceWith(base, name, newval), expected)

        # Out of bounds.
        base = theclass(2000, 2, 29)
        expect(ValueError):
          _ = base.replace(year=2001)
