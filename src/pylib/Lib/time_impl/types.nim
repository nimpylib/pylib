
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

func repr*(st: struct_time): string =
  ## struct_time.__repr__
  ## 
  ## returns string starting with `"time.struct_time"`
  ## with 9 fields.
  # len "time.struct_time()": 18
  # fields' names: 61; equal signs: 9; ", ": 16; fields' value: <=20
  # sum up to 124
  result = newStringOfCap 124
  result.add "time.struct_time("
  result.addFields(st, STRUCT_TM_ITEMS)
  result.add ")"


template genOrder(cmpOp){.dirty.} =
  func cmpOp*(a, b: struct_time): bool =
    ## compares based on fields.
    orderOnFields a, b, cmpOp
  func cmpOp*(a: struct_time, b: struct_time_tuple11): bool =
    ## compares based on fields.
    mixinOrderOnFields a, b, cmpOp, cmpStragy=csLhs
  func cmpOp*(a: struct_time_tuple11, b: struct_time): bool =
    ## compares based on fields.
    mixinOrderOnFields a, b, cmpOp, cmpStragy=csRhs

genOrder `==`
genOrder `<=`
genOrder `<`

using st: struct_time

func `==`*(st; t: tuple): bool{.inline.} = false
func `==`*(t: tuple; st): bool{.inline.} = false

func cmp(st; t: tuple): int = cmpOnField st, t
func cmp(t: tuple; st): int = -cmp(st, t)

template genOrderOnCmp(cmpOp){.dirty.} =
  func cmpOp*(st; t: tuple): bool = cmpOp cmp(st, t), 0
  func cmpOp*(t: tuple; st): bool = cmpOp cmp(t, st), 0

genOrderOnCmp `<`
genOrderOnCmp `<=`
