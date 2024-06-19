
import std/times
import ./private/macro_utils

type
  struct_time* = ref object
    tm_year*: int
    tm_mon*: range[1 .. 12]
    tm_mday*: MonthdayRange
    tm_hour*: HourRange
    tm_min*: MinuteRange
    tm_sec*: range[0 .. 61]  # SecondRange is range[0 .. 60]
    tm_wday*: range[0 .. 6]
    tm_yday*: range[1 .. 366]  # YeardayRange is range[0 .. 365]
    tm_isdst*: int
    tm_zone*: string  ## .. warning:: curently is only "LOCAL" or "Etc/UTC"
    tm_gmtoff*: int

const STRUCT_TM_ITEMS = 9

declTupleWithNFieldsFrom(struct_time_tuple, struct_time, STRUCT_TM_ITEMS)
declTupleWithNFieldsFrom(struct_time_tuple10, struct_time, STRUCT_TM_ITEMS+1)
declTupleWithNFieldsFrom(struct_time_tuple11, struct_time, STRUCT_TM_ITEMS+2)

type
  Some_struct_time_tuple* = struct_time_tuple | struct_time_tuple10 | struct_time_tuple11
  Some_struct_time* = struct_time | Some_struct_time_tuple

template isUtcZone*(st: struct_time): bool =
  ## zone is only local or utc
  st.tm_gmtoff == 0

template initStructTime*(): struct_time =
  bind struct_time
  struct_time(
    tm_year: 1900,
    tm_mon: 1, tm_mday: 1,
    tm_yday: 1,
    tm_isdst: -1)

template initStructTime*(
    year,
    mon,
    mday,
    hour,
    min,
    sec,
    wday,
    yday,
    isdst,
    zone,
    gmtoff
): struct_time =
  bind struct_time
  struct_time(
    tm_year:  year,
    tm_mon:   mon,
    tm_mday:  mday,
    tm_hour:  hour,
    tm_min:   min,
    tm_sec:   sec,
    tm_wday:  wday,
    tm_yday:  yday,
    tm_isdst: isdst,
    tm_zone:  zone,
    tm_gmtoff:gmtoff
  )
