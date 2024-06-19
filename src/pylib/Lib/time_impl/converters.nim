
import ./types
import ./private/macro_utils
import std/times

template gen_init(tupType) =
  func struct_time*(tup: tupType): struct_time =
    result = initStructTime()
    asgSeqToObj(tup, result)

gen_init struct_time_tuple
gen_init struct_time_tuple10
gen_init struct_time_tuple11

converter toTuple*(st: struct_time): struct_time_tuple =
  ## XXX: `tuple` is Nim's keyword, so no symbol can be named `tuple`
  (
    st.tm_year,
    st.tm_mon,
    st.tm_mday,
    st.tm_hour,
    st.tm_min,
    st.tm_sec,
    st.tm_wday,
    st.tm_yday,
    st.tm_isdst,
  )

func dtToStructTime*(dt: DateTime, res: var struct_time) =
  res = initStructTime(
    dt.year,
    dt.month.int,
    dt.monthday,
    dt.hour,
    dt.minute,
    dt.second,
    dt.weekday.int,
    dt.yearday + 1,
    dt.isDst.int,
    dt.timezone.name,
    -dt.utcOffset
  )

func structTimeToDt*(st: struct_time, res: var DateTime) =
  let mon = st.tm_mon.Month
  {.noSideEffect.}:
    res = dateTime(
      st.tm_year,
      mon,
      st.tm_mday,
      st.tm_hour,
      st.tm_min,
      st.tm_sec,
      zone=(if st.isUtcZone: utc() else: local())
    )
  assert st.tm_wday == res.weekday.int
