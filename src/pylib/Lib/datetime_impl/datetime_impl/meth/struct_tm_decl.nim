

{.push header: "<time.h>".}

type
  struct_tm*{.importc: "struct tm", completeStruct.} = object

const HAVE_STRUCT_TM_TM_ZONE* = sizeof(struct_tm) > 9*sizeof(cint)

when not HAVE_STRUCT_TM_TM_ZONE:
  type Tm*{.importc: "struct tm".} = object
    tm_year*: int  ## years since 1900
    tm_mon*:  range[0 .. 11]
    tm_mday*: range[1 .. 31]
    tm_hour*: range[0 .. 23]
    tm_min*:  range[0 .. 59]
    tm_sec*:  range[0 .. 61]  ## C89 is 0..61, C99 is 0..60
    tm_wday*: range[0 .. 6]
    tm_yday*: range[0 .. 365] 
    tm_isdst*: int
else:
  type Tm*{.importc: "struct tm".} = object
    tm_year*: int  ## years since 1900
    tm_mon*:  range[0 .. 11]
    tm_mday*: range[1 .. 31]
    tm_hour*: range[0 .. 23]
    tm_min*:  range[0 .. 59]
    tm_sec*:  range[0 .. 61]  ## C89 is 0..61, C99 is 0..60
    tm_wday*: range[0 .. 6]
    tm_yday*: range[0 .. 365] 
    tm_isdst*: int
    tm_gmtoff*: clong
    tm_zone*: cstring

{.pop.}

func initTm*(tm: var Tm) =
  # a workaround for compile error
  tm.tm_mday = 1
func initTm*: Tm = result.initTm()
