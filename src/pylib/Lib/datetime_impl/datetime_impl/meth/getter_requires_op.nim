
include ./common
import ./op
from ./state_consts import CONST_EPOCH
from ./to_seconds_utils import local_to_seconds
import ../../timezone_impl/decl
import ../../timedelta_impl/meth

const EPOCH_SECONDS = BiggestInt(719163) * 24 * 60 * 60
# date(1970,1,1).toordinal() == 719163

using self: datetime
proc timestamp*(self): float =
  if not self.tzinfo.isTzNone:
    let delta = self - CONST_EPOCH
    result = delta.total_seconds
  else:
    let seconds = local_to_seconds(
      self.year, self.month, self.day,
      self.hour, self.minute, self.second,
      self.fold
    )
    
    result = float(seconds - EPOCH_SECONDS) + self.microsecond / 1_000_000


