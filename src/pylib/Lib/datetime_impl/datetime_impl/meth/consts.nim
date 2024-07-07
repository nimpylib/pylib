
include ./common
import ./init
import ./inner_consts
import ../../timedelta_impl/decl

func max*(_: typedesc[datetime]): datetime = datetime(MAXYEAR, 12, 31, 23, 59, 59, 999999)
func min*(_: typedesc[datetime]): datetime = datetime.datetime(MINYEAR, 1, 1, 0, 0)
func resolution*(_: typedesc[datetime]): timedelta = timedelta.resolution
