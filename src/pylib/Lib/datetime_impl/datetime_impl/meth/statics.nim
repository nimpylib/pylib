
include ./common
import ../../timezone_impl/decl
import std/times

func today*(_: typedesc[datetime]): datetime = newDatetime now()
func now*(_: typedesc[datetime], tzinfo: tzinfo = TzNone): datetime =
  newDatetime(now(), tzinfo)
