
include ./common
from ../../mathutils import divmod
import std/times
from ./calendar_utils import ymd_to_ord, weekday, YWD, iso_week1_monday
## date

# XXX: TODO: using self: date
using self: datetime
func toordinal*(self): int =
  ## date.toordinal()
  ymd_to_ord(self.year, self.month, self.day)

func weekday*(self): int =
  self.asNimDatetime.weekday.int

func isoweekday*(self): int =
  let dow = weekday(self.year, self.month, self.day)
  dow + 1

func isocalendar*(self): YWD =
  var
    year = self.year
    week1_monday = iso_week1_monday(year)
  let
    today = ymd_to_ord(year, self.month, self.day)
  var day: int
  var week = divmod(today - week1_monday, 7, day)
  if week < 0:
    year.dec
    week1_monday = iso_week1_monday(year)
    week = divmod(today - week1_monday, 7, day)
  elif week >= 52 and today >= iso_week1_monday(year + 1):
    year.inc
    week = 0

  result = YWD (year, week+1, day+1)
