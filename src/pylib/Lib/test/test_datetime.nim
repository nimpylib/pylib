
import ./import_utils
importTestPyLib datetime

let
  ZERO = timedelta(0)
  MINUTE = timedelta(minutes=1)
  HOUR = timedelta(hours=1)
  DAY = timedelta(days=1)
  DT = datetime(1970, 1, 1)

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
