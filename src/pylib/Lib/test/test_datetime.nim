
import ./import_utils
importTestPyLib datetime

let
  #ZERO = timedelta(0)
  #MINUTE = timedelta(minutes=1)
  HOUR = timedelta(hours=1)
  #DAY = timedelta(days=1)
  DT = datetime(1970, 1, 1)

template assertEqual(a, b) = check a == b

template theclass: untyped = PyDatetime
template theclass(x: untyped, xs: varargs[untyped]): untyped =
  init.datetime(x, xs)
from std/sugar import collect
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

    def test_isoformat_timezone():
        tzoffsets = [
            ("05:00", timedelta(hours=5)),
            ("02:00", timedelta(hours=2)),
            ("06:27", timedelta(hours=6, minutes=27)),
            ("12:32:30", timedelta(hours=12, minutes=32, seconds=30)),
            ("02:04:09.123456", timedelta(hours=2, minutes=4, seconds=9, microseconds=123456))
        ]
        # XXX: NIM-BUG:
        # if using list here on debian when JS, you will get:
        #  Error: internal error: genTypeInfo(tyInferred)
        tmp_tzinfos = ([
            (str(""), None.noneToTzInfo),
            (str("+00:00"), UTC),
            (str("+00:00"), timezone(timedelta(0))),
        ])
        #when defined(js) and defined(debian):
        tzinfos = @tmp_tzinfos

        for (expected, td) in tzoffsets:
          for (prefix, sign) in [("-", -1), ("+", 1)]:
            tzinfos.add(
              (prefix + expected, tzinfo(timezone(sign * td)))
            )
        dt_base = theclass(2016, 4, 1, 12, 37, 9)
        exp_base = "2016-04-01T12:37:09"

        for (exp_tz, tzi) in tzinfos:
            dt = dt_base.replace(tzinfo=tzi)
            exp = exp_base + exp_tz
            check dt.isoformat() == exp
    test_isoformat_timezone()

  suite "fromisoformat":
    test "if reversible":
      let 
        # XXX: NIM-BUG: if places following in `def` without `let`:
#[ nim-2.2.0
error: too few arguments to function  eqcopy___OOZsrcZpylibZ76ibZdatetime95implZtimezone95implZdecl_u375'
 1688 |                                         nimlf_(161, "E:\\program\\utils\\pylib\\src\\pylib\\Lib\\datetime_impl\\timezone_impl\\decl.nim");                                      eqcopy___OOZsrcZpylibZ76ibZdatetime95implZtimezone95implZdecl_u375(&v, v_2);
      |
                                                                ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
]#
        tzinfos = [None.noneToTzInfo, datetime.UTC,
                   timezone(timedelta(hours = -5)),
                   timezone(timedelta(hours = 2))]
      def test_fromisoformat_datetime():
        # Test that isoformat() is reversible
        base_dates = [
            (1, 1, 1),
            (1900, 1, 1),
            (2004, 11, 12),
            (2017, 5, 30)
        ]

        base_times = [
            (0, 0, 0, 0),
            (0, 0, 0, 241000),
            (0, 0, 0, 234567),
            (12, 30, 45, 234567)
        ]

        separators = [' ', 'T']

        dts = collect:
          for date_tuple in base_dates:
            for time_tuple in base_times:
              for tzi in tzinfos:
                theclass(
                  date_tuple[0], date_tuple[1], date_tuple[2],
                  time_tuple[0], time_tuple[1], time_tuple[2], time_tuple[3],
                  tzinfo=tzi
                )

        for dt in dts:
            for sep in separators:
                dtstr = dt.isoformat(sep=sep)
                dt_rt = theclass.fromisoformat(dtstr)
                assertEqual(dt, dt_rt)
      test_fromisoformat_datetime()

    #[ C compile error in list([timedelta(..)...])
    def test_fromisoformat_timezone():
        base_dt = theclass(2014, 12, 30, 12, 30, 45, 217456)

        tzoffsets = list([
            timedelta(hours=5), timedelta(hours=2),
            timedelta(hours=6, minutes=27),
            timedelta(hours=12, minutes=32, seconds=30),
            timedelta(hours=2, minutes=4, seconds=9, microseconds=123456)
        ])

        for td in tzoffsets:
          tzoffsets.append(-1 * td)

        tzinfos = list([None.noneToTzInfo, UTC,
                   timezone(timedelta(hours=0))])

        for td in tzoffsets:
          tzinfos.append(timezone(td))

        for tzi in tzinfos:
            dt = base_dt.replace(tzinfo=tzi)
            dtstr = dt.isoformat()

            dt_rt = theclass.fromisoformat(dtstr)
            check dt == dt_rt
    test_fromisoformat_timezone()
    ]#

    def test_fromisoformat_separators():
        separators = [
            " ", "T", "\u007f",     # 1-bit widths
            "\u0080", "ʁ",          # 2-bit widths
            "ᛇ", "時",               # 3-bit widths
            "🐍",                    # 4-bit widths
            "\ud800",               # bpo-34454: Surrogate code point
        ]

        for sep in separators:
            dt = theclass(2018, 1, 31, 23, 59, 47, 124789)
            dtstr = dt.isoformat(sep=sep)

            dt_rt = theclass.fromisoformat(dtstr)
            assertEqual(dt, dt_rt)
    test_fromisoformat_separators()

    def test_fromisoformat_ambiguous():
        # Test strings like 2018-01-31+12:15 (where +12:15 is not a time zone)
        separators = ['+', '-']
        for sep in separators:
            dt = theclass(2018, 1, 31, 12, 15)
            dtstr = dt.isoformat(sep=sep)

            block:
                dt_rt = theclass.fromisoformat(dtstr)
                assertEqual(dt, dt_rt)
    test_fromisoformat_ambiguous()

    #[ hard to rewrite
    def test_fromisoformat_timespecs():
        datetime_bases = [
            (2009, 12, 4, 8, 17, 45, 123456),
            (2009, 12, 4, 8, 17, 45, 0)]

        tzinfos = [None, timezone.utc,
                   timezone(timedelta(hours=-5)),
                   timezone(timedelta(hours=2)),
                   timezone(timedelta(hours=6, minutes=27))]

        timespecs = ["hours", "minutes", "seconds",
                     "milliseconds", "microseconds"]

        for ip, ts in enumerate(timespecs):
            for tzi in tzinfos:
                for dt_tuple in datetime_bases:
                    if ts == "milliseconds":
                        new_microseconds = 1000 * (dt_tuple[6] // 1000)
                        dt_tuple = dt_tuple[0:6] + (new_microseconds,)

                    dt = theclass(*(dt_tuple[0:(4 + ip)]), tzinfo=tzi)
                    dtstr = dt.isoformat(timespec=ts)
                    block:
                        dt_rt = theclass.fromisoformat(dtstr)
                        assertEqual(dt, dt_rt)
    test_fromisoformat_timespecs()
    ]#

    def test_fromisoformat_datetime_examples():
        BST = timezone(timedelta(hours=1), "BST")
        EST = timezone(timedelta(hours = -5), "EST")
        EDT = timezone(timedelta(hours = -4), "EDT")
        examples = [
            ("2025-01-02", theclass(2025, 1, 2, 0, 0)),
            ("2025-01-02T03", theclass(2025, 1, 2, 3, 0)),
            ("2025-01-02T03:04", theclass(2025, 1, 2, 3, 4)),
            ("2025-01-02T0304", theclass(2025, 1, 2, 3, 4)),
            ("2025-01-02T03:04:05", theclass(2025, 1, 2, 3, 4, 5)),
            ("2025-01-02T030405", theclass(2025, 1, 2, 3, 4, 5)),
            ("2025-01-02T03:04:05.6",
             theclass(2025, 1, 2, 3, 4, 5, 600000)),
            ("2025-01-02T03:04:05,6",
             theclass(2025, 1, 2, 3, 4, 5, 600000)),
            ("2025-01-02T03:04:05.678",
             theclass(2025, 1, 2, 3, 4, 5, 678000)),
            ("2025-01-02T03:04:05.678901",
             theclass(2025, 1, 2, 3, 4, 5, 678901)),
            ("2025-01-02T03:04:05,678901",
             theclass(2025, 1, 2, 3, 4, 5, 678901)),
            ("2025-01-02T030405.678901",
             theclass(2025, 1, 2, 3, 4, 5, 678901)),
            ("2025-01-02T030405,678901",
             theclass(2025, 1, 2, 3, 4, 5, 678901)),
            ("2025-01-02T03:04:05.6789010",
             theclass(2025, 1, 2, 3, 4, 5, 678901)),
            ("2009-04-19T03:15:45.2345",
             theclass(2009, 4, 19, 3, 15, 45, 234500)),
            ("2009-04-19T03:15:45.1234567",
             theclass(2009, 4, 19, 3, 15, 45, 123456)),
            ("2025-01-02T03:04:05,678",
             theclass(2025, 1, 2, 3, 4, 5, 678000)),
            ("20250102", theclass(2025, 1, 2, 0, 0)),
            ("20250102T03", theclass(2025, 1, 2, 3, 0)),
            ("20250102T03:04", theclass(2025, 1, 2, 3, 4)),
            ("20250102T03:04:05", theclass(2025, 1, 2, 3, 4, 5)),
            ("20250102T030405", theclass(2025, 1, 2, 3, 4, 5)),
            ("20250102T03:04:05.6",
             theclass(2025, 1, 2, 3, 4, 5, 600000)),
            ("20250102T03:04:05,6",
             theclass(2025, 1, 2, 3, 4, 5, 600000)),
            ("20250102T03:04:05.678",
             theclass(2025, 1, 2, 3, 4, 5, 678000)),
            ("20250102T03:04:05,678",
             theclass(2025, 1, 2, 3, 4, 5, 678000)),
            ("20250102T03:04:05.678901",
             theclass(2025, 1, 2, 3, 4, 5, 678901)),
            ("20250102T030405.678901",
             theclass(2025, 1, 2, 3, 4, 5, 678901)),
            ("20250102T030405,678901",
             theclass(2025, 1, 2, 3, 4, 5, 678901)),
            ("20250102T030405.6789010",
             theclass(2025, 1, 2, 3, 4, 5, 678901)),
            ("2022W01", theclass(2022, 1, 3)),
            ("2022W52520", theclass(2022, 12, 26, 20, 0)),
            ("2022W527520", theclass(2023, 1, 1, 20, 0)),  # meaning 2022W527T20, a.k.a. 5 before 20 is just a sep
            ("2026W01516", theclass(2025, 12, 29, 16, 0)),
            ("2026W013516", theclass(2025, 12, 31, 16, 0)),
            ("2025W01503", theclass(2024, 12, 30, 3, 0)),
            ("2025W014503", theclass(2025, 1, 2, 3, 0)),
            ("2025W01512", theclass(2024, 12, 30, 12, 0)),
            ("2025W014512", theclass(2025, 1, 2, 12, 0)),
            ("2025W014T121431", theclass(2025, 1, 2, 12, 14, 31)),
            ("2026W013T162100", theclass(2025, 12, 31, 16, 21)),
            ("2026W013 162100", theclass(2025, 12, 31, 16, 21)),
            ("2022W527T202159", theclass(2023, 1, 1, 20, 21, 59)),
            ("2022W527 202159", theclass(2023, 1, 1, 20, 21, 59)),
            ("2025W014 121431", theclass(2025, 1, 2, 12, 14, 31)),
            ("2025W014T030405", theclass(2025, 1, 2, 3, 4, 5)),
            ("2025W014 030405", theclass(2025, 1, 2, 3, 4, 5)),
            ("2020-W53-6T03:04:05", theclass(2021, 1, 2, 3, 4, 5)),
            ("2020W537 03:04:05", theclass(2021, 1, 3, 3, 4, 5)),
            ("2025-W01-4T03:04:05", theclass(2025, 1, 2, 3, 4, 5)),
            ("2025-W01-4T03:04:05.678901",
             theclass(2025, 1, 2, 3, 4, 5, 678901)),
            ("2025-W01-4T12:14:31", theclass(2025, 1, 2, 12, 14, 31)),
            ("2025-W01-4T12:14:31.012345",
             theclass(2025, 1, 2, 12, 14, 31, 12345)),
            ("2026-W01-3T16:21:00", theclass(2025, 12, 31, 16, 21)),
            ("2026-W01-3T16:21:00.000000", theclass(2025, 12, 31, 16, 21)),
            ("2022-W52-7T20:21:59",
             theclass(2023, 1, 1, 20, 21, 59)),
            ("2022-W52-7T20:21:59.999999",
             theclass(2023, 1, 1, 20, 21, 59, 999999)),
            ("2025-W01003+00",
             theclass(2024, 12, 30, 3, 0, tzinfo=UTC)),
            ("2025-01-02T03:04:05+00",
             theclass(2025, 1, 2, 3, 4, 5, tzinfo=UTC)),
            ("2025-01-02T03:04:05Z",
             theclass(2025, 1, 2, 3, 4, 5, tzinfo=UTC)),
            ("2025-01-02003:04:05,6+00:00:00.00",
             theclass(2025, 1, 2, 3, 4, 5, 600000, tzinfo=UTC)),
            ("2000-01-01T00+21",
             theclass(2000, 1, 1, 0, 0, tzinfo=timezone(timedelta(hours=21)))),
            ("2025-01-02T03:05:06+0300",
             theclass(2025, 1, 2, 3, 5, 6,
                           tzinfo=timezone(timedelta(hours=3)))),
            ("2025-01-02T03:05:06-0300",
             theclass(2025, 1, 2, 3, 5, 6,
                           tzinfo=timezone(timedelta(hours = -3)))),
            ("2025-01-02T03:04:05+0000",
             theclass(2025, 1, 2, 3, 4, 5, tzinfo=UTC)),
            ("2025-01-02T03:05:06+03",
             theclass(2025, 1, 2, 3, 5, 6,
                           tzinfo=timezone(timedelta(hours=3)))),
            ("2025-01-02T03:05:06-03",
             theclass(2025, 1, 2, 3, 5, 6,
                           tzinfo=timezone(timedelta(hours = -3)))),
            ("2020-01-01T03:05:07.123457-05:00",
             theclass(2020, 1, 1, 3, 5, 7, 123457, tzinfo=EST)),
            ("2020-01-01T03:05:07.123457-0500",
             theclass(2020, 1, 1, 3, 5, 7, 123457, tzinfo=EST)),
            ("2020-06-01T04:05:06.111111-04:00",
             theclass(2020, 6, 1, 4, 5, 6, 111111, tzinfo=EDT)),
            ("2020-06-01T04:05:06.111111-0400",
             theclass(2020, 6, 1, 4, 5, 6, 111111, tzinfo=EDT)),
            ("2021-10-31T01:30:00.000000+01:00",
             theclass(2021, 10, 31, 1, 30, tzinfo=BST)),
            ("2021-10-31T01:30:00.000000+0100",
             theclass(2021, 10, 31, 1, 30, tzinfo=BST)),
            ("2025-01-02T03:04:05,6+000000.00",
             theclass(2025, 1, 2, 3, 4, 5, 600000, tzinfo=UTC)),
            ("2025-01-02T03:04:05,678+00:00:10",
             theclass(2025, 1, 2, 3, 4, 5, 678000,
                           tzinfo=timezone(timedelta(seconds=10)))),
        ]

        for (input_str, expected) in examples:
            block:
                actual = theclass.fromisoformat(input_str)
                assertEqual(actual, expected)
    test_fromisoformat_datetime_examples()

    def test_fromisoformat_fails_datetime():
        # Test that fromisoformat() fails on invalid values
        bad_strs = [
            "",                             # Empty string
            "\ud800",                       # bpo-34454: Surrogate code point
            "2009.04-19T03",                # Wrong first separator
            "2009-04.19T03",                # Wrong second separator
            "2009-04-19T0a",                # Invalid hours
            "2009-04-19T03:1a:45",          # Invalid minutes
            "2009-04-19T03:15:4a",          # Invalid seconds
            "2009-04-19T03;15:45",          # Bad first time separator
            "2009-04-19T03:15;45",          # Bad second time separator
            "2009-04-19T03:15:4500:00",     # Bad time zone separator
            "2009-04-19T03:15:45.123456+24:30",    # Invalid time zone offset
            "2009-04-19T03:15:45.123456-24:30",    # Invalid negative offset
            "2009-04-10ᛇᛇᛇᛇᛇ12:15",         # Too many unicode separators
            "2009-04\ud80010T12:15",        # Surrogate char in date
            "2009-04-10T12\ud80015",        # Surrogate char in time
            "2009-04-19T1",                 # Incomplete hours
            "2009-04-19T12:3",              # Incomplete minutes
            "2009-04-19T12:30:4",           # Incomplete seconds
            "2009-04-19T12:",               # Ends with time separator
            "2009-04-19T12:30:",            # Ends with time separator
            "2009-04-19T12:30:45.",         # Ends with time separator
            "2009-04-19T12:30:45.123456+",  # Ends with timzone separator
            "2009-04-19T12:30:45.123456-",  # Ends with timzone separator
            "2009-04-19T12:30:45.123456-05:00a",    # Extra text
            "2009-04-19T12:30:45.123-05:00a",       # Extra text
            "2009-04-19T12:30:45-05:00a",           # Extra text
        ]

        for bad_str in bad_strs:
            block:
                expect(ValueError):
                    _ = theclass.fromisoformat(bad_str)
    test_fromisoformat_fails_datetime()

    def test_fromisoformat_utc():
        dt_str = "2014-04-19T13:21:13+00:00"
        dt = theclass.fromisoformat(dt_str)

        assertEqual(dt.tzinfo, UTC)
    test_fromisoformat_fails_datetime()
    test_fromisoformat_utc()

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

  test "stringify":
    template eq(a, b) = check a == b
    def test_str():

        eq(str(timedelta(1)), "1 day, 0:00:00")
        eq(str(timedelta(-1)), "-1 day, 0:00:00")
        eq(str(timedelta(2)), "2 days, 0:00:00")
        eq(str(timedelta(-2)), "-2 days, 0:00:00")

        eq(str(timedelta(hours=12, minutes=58, seconds=59)), "12:58:59")
        eq(str(timedelta(hours=2, minutes=3, seconds=4)), "2:03:04")
        eq(str(timedelta(weeks = -30, hours=23, minutes=12, seconds=34)),
           "-210 days, 23:12:34")

        eq(str(timedelta(milliseconds=1)), "0:00:00.001000")
        eq(str(timedelta(microseconds=3)), "0:00:00.000003")

        # may overflow int64
        #eq(str(timedelta(days=999999999, hours=23, minutes=59, seconds=59,
        #           microseconds=999999)),
        #   "999999999 days, 23:59:59.999999")
    test_str()


import std/macros
suite "date":
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
      #base = meth(ts)
      # Try with and without naming the keyword.
      off42 = newFixedOffset(42, "42")
      another = meth(ts, off42)
      #again = meth(ts, tz=off42)
      #assertIs(another.tzinfo, again.tzinfo)
      assertEqual(another.utcoffset(), timedelta(minutes=42))
    test_tzinfo_fromtimestamp()
