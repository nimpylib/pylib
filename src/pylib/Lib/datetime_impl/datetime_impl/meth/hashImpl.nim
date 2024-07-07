
import std/hashes
include ./common
import ./getter
import ../../timezone_impl/[decl, meth_by_datetime]
import ../../timedelta_impl/[decl, meth]  # import `-`, init for hash
from ./importer import ymd_to_ord

proc hashImpl(self: datetime): int =
  let self0 =
    if self.isfold:
      newDatetime(self, isfold=false)
    else: self
  let offset = self0.utcoffset()
  if offset.isTimeDeltaNone:
    result = hash [
          self.year,
          self.month, self.day,
          self.hour, self.minute, self.second, self.microsecond,
    ]
  else:
    let days = ymd_to_ord(
      self.year, self.month, self.day)
    let seconds = self.hour * 3600 +
                  self.minute * 60 + self.second
    let temp1 = newTimedelta(days=days, seconds=seconds,
                  microseconds=self.microsecond, true)
    let temp2 = temp1 - offset
    result = hash temp2

proc hash*(self: datetime): int =
  if self.hashcode == -1:
    self.hashcode = self.hashImpl()
  result = self.hashcode
