
import ./import_utils
importPyLib()
pyimport datetime

import std/unittest


test "utcoffset":
  let
    ZERO = timedelta(0)
    MINUTE = timedelta(minutes=1)
    HOUR = timedelta(hours=1)
    DAY = timedelta(days=1)
    DT = datetime(1970, 1, 1)
  template assertEqual(a, b) = check a == b 
  def test_utcoffset():
    dummy = DT
    for h in [0.0, 1.5, 12.0]:
        offset = h * HOUR
        assertEqual(offset, timezone(offset).utcoffset(dummy))
        assertEqual(-offset, timezone(-offset).utcoffset(dummy))
  test_utcoffset()
