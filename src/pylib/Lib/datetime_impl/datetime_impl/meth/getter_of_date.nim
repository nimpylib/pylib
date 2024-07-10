
include ./common
import std/times
from ./calendar_utils import ymd_to_ord, weekday
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
