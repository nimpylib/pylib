
import std/times

type
  struct_time_tuple* = tuple
    tm_year: int
    tm_mon: range[1 .. 12]
    tm_mday: MonthdayRange
    tm_hour: HourRange
    tm_min: MinuteRange
    tm_sec: range[0 .. 61]  # SecondRange is range[0 .. 60]
    tm_wday: range[0 .. 6]
    tm_yday: range[0 .. 366]  # YeardayRange is range[0 .. 365]
    tm_isdst: int
  
  struct_time* = ref object
    tm_year*: int
    tm_mon*: range[1 .. 12]
    tm_mday*: MonthdayRange
    tm_hour*: HourRange
    tm_min*: MinuteRange
    tm_sec*: range[0 .. 61]  # SecondRange is range[0 .. 60]
    tm_wday*: range[0 .. 6]
    tm_yday*: range[0 .. 366]  # YeardayRange is range[0 .. 365]
    tm_isdst*: int
    tm_zone*: string  ## .. warning:: curently is only "LOCAL" or "Etc/UTC"
    tm_gmtoff*: int

template isUtcZone*(st: struct_time): bool =
  ## zone is only local or utc
  st.tm_gmtoff == 0

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
  ): struct_time = struct_time(
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
