
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
