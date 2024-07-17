

when defined(js):
  const HAVE_STRUCT_TM_TM_ZONE* = true
  {.pragma: TmPragma.}
else:
  type struct_tm*{.importc: "struct tm", header: "<time.h>", completeStruct.} = object
  const HAVE_STRUCT_TM_TM_ZONE* = sizeof(struct_tm) > 9*sizeof(cint)
  {.pragma: TmPragma, importc: "struct tm", header: "<time.h>".}

when not HAVE_STRUCT_TM_TM_ZONE:
  type Tm*{.TmPragma.} = object
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
  type Tm*{.TmPragma.} = object
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

func year*(tm: Tm): int = tm.tm_year + 1900
func month*(tm: Tm): int = tm.tm_mon + 1

func initTm*: Tm = Tm(tm_mday: 1)
template initTm*(tm: var Tm) =
  # a workaround for compile error
  bind initTm
  tm = initTm()
