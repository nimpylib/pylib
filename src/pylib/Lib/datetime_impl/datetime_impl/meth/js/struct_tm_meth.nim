

import std/jscore
import std/macros
import ./jstime_utils
from ../calendar_utils import days_before_month
import ../struct_tm_decl

let tzname = getTimeZoneName()

#[
func getFullYear(d: DateTime): int{.importjs.}
func getUTCFullYear(d: DateTime): int{.importjs.}
wrap year,    getFullYear
]#
template wrap(name) =
  func name(d: DateTime): int{.importcpp.}

wrap getDate
func getUTCYear(d: DateTime): int = d.getUTCFullYear - 1900

func getYearDay(year, month, day: int): int =
  # or
  #floor((date - new Date(date.getFullYear(), 0, 0)) / 1000 / 60 / 60 / 24)
  day + days_before_month(year, month)

macro initAttrs(utc: static[bool], tm: Tm; dt: DateTime; attrs: varargs[untyped]) =
  result = newStmtList()
  for t in attrs:
    let attr = t[0]
    result.add newAssignment(
      newDotExpr(tm, attr),
      newCall(
        if utc: t[2]
        else:   t[1],
      dt)
    )


template initWith(tm: Tm; dt: DateTime, utc: static[bool]) =
  initAttrs(utc, tm, dt
    ,(tm_year ,getYear   ,getUTCYear   )
    ,(tm_mon  ,getMonth  ,getUTCMonth  )
    ,(tm_mday ,getDate   ,getUTCDate   )
    ,(tm_wday ,getDay    ,getUTCDay    )
                          
    ,(tm_hour ,getHours  ,getUTCHours  )
    ,(tm_min  ,getMinutes,getUTCMinutes)
    ,(tm_sec  ,getSeconds,getUTCSeconds)
  )
  tm.tm_yday = getYearDay(tm.year, tm.month, tm.tm_mday)

using tm: Tm
func getUtcOffset(dt: DateTime): clong =
  -60 * dt.getTimezoneOffset  # in minutes -> in seconds

# ---- required by ./time.nim ----

using ordinal: int|int64

wrap valueOf
func isNaN(n: int): bool{.importjs: "isNaN(#)".}
proc newCheckedDate(ordinal): DateTime =
  result = newDate(ordinal)
  when not defined(release):
    let val = result.valueOf()
    if isNaN(val):
      raise newException(OSError,
        "Given ordinal value is out of valid value for JS'`new Date`: " & $val)

proc tm_from_local*(ordinal): Tm =
  result.initTm
  let date = newCheckedDate(ordinal)
  result.initWith date, utc=false
  result.tm_gmtoff = date.getUtcOffset
  result.tm_zone = tzname

proc tm_from_utc*(ordinal): Tm =
  result.initTm
  let date = newCheckedDate(ordinal)
  result.initWith date, utc=true
  result.tm_gmtoff = 0
  result.tm_zone = "UTC"
