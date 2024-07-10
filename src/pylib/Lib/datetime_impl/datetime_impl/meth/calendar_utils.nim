# translated from CPython-3.14.0-alpha/Modules/_datetimemodule.c
##[
 General calendrical helper functions
 
 For each month ordinal in 1..12, the number of days in that month,
 and the number of days before that month in the same year.  These
 are correct for non-leap years only.
]##

import std/times
from ./inner_consts import MINYEAR, MAXYEAR 

template days_in_month(year, month: int): int = getDaysInMonth(month.Month, year)

template is_leap(year): bool = isLeapYear(year)

const arr_days_before_month: array[1..12, int] = [
  0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]

func days_before_month(year, month: int): int =
  ## year, month -> number of days in year preceding first day of month

  assert(month >= 1);
  assert(month <= 12);
  result = arr_days_before_month[month];
  if month > 2 and is_leap(year):
    result.inc

func days_before_year(year: int): int =
  ## year -> number of days before January 1st of year.  Remember that we
  ## start with year 1, so days_before_year(1) == 0.
  let y = year - 1;
  #[ This is incorrect if year <= 0; we really want the floor
     here.  But so long as MINYEAR is 1, the smallest year this
     can see is 1.
  ]#
  assert (year >= 1);
  return y*365 + y div 4 - y div 100 + y div 400

func ymd_to_ord*(year, month, day: int): int =
  ## year, month, day -> ordinal, considering 01-Jan-0001 as day 1.
  days_before_year(year) + days_before_month(year, month) + day;


const
  DI4Y = 1461 ##  Number of days in 4, 100, and 400 year cycles.  That these have
            ##  the correct values is asserted in the module init function.
            ##
  DI100Y = 36524
  DI400Y = 146097

type
  YMD* = tuple[
    year, month, day: int
  ]
proc ord_to_ymd*(ordinal: int, result: var YMD) =
  ##  ordinal -> year, month, day, considering 01-Jan-0001 as day 1.

  ##  ordinal is a 1-based index, starting at 1-Jan-1.  The pattern of
  ##  leap years repeats exactly every 400 years.  The basic strategy is
  ##  to find the closest 400-year boundary at or before ordinal, then
  ##  work with the offset from that boundary to ordinal.  Life is much
  ##  clearer if we subtract 1 from ordinal first -- then the values
  ##  of ordinal at 400-year boundaries are exactly those divisible
  ##  by DI400Y:
  ##
  ##     D  M   Y            n              n-1
  ##     -- --- ----        ----------     ----------------
  ##     31 Dec -400        -DI400Y       -DI400Y -1
  ##      1 Jan -399         -DI400Y +1   -DI400Y      400-year boundary
  ##     ...
  ##     30 Dec  000        -1             -2
  ##     31 Dec  000         0             -1
  ##      1 Jan  001         1              0          400-year boundary
  ##      2 Jan  001         2              1
  ##      3 Jan  001         3              2
  ##     ...
  ##     31 Dec  400         DI400Y        DI400Y -1
  ##      1 Jan  401         DI400Y +1     DI400Y      400-year boundary
  ##
  assert(ordinal >= 1)
  let ordinal = ordinal - 1
  let n400 = ordinal div DI400Y
  var n = ordinal mod DI400Y
  result.year = n400 * 400 + 1
  #  Now n is the (non-negative) offset, in days, from January 1 of
  #  year, to the desired date.  Now compute how many 100-year cycles
  #  precede n.
  #  Note that it's possible for n100 to equal 4!  In that case 4 full
  #  100-year cycles precede the desired day, which implies the
  #  desired day is December 31 at the end of a 400-year cycle.
  #
  let n100 = n div DI100Y
  n = n mod DI100Y
  #  Now compute how many 4-year cycles precede it.
  let n4 = n div DI4Y
  n = n mod DI4Y
  #  And now how many single years.  Again n1 can be 4, and again
  #  meaning that the desired day is December 31 at the end of the
  #  4-year cycle.
  #
  let n1 = n div 365
  n = n mod 365
  inc(result.year, n100 * 100 + n4 * 4 + n1)
  if n1 == 4 or n100 == 4:
    assert(n == 0)
    dec(result.year, 1)
    result.month = 12
    result.day = 31
    return
  let leapyear = n1 == 3 and (n4 != 24 or n100 == 3)
  assert(leapyear == is_leap(result.year))
  result.month = (n + 50) shr 5
  var preceding = (arr_days_before_month[result.month] +
                   int(result.month > 2 and leapyear))
  if preceding > n:
    ##  estimate is too large
    dec(result.month, 1)
    dec(preceding, days_in_month(result.year, result.month))
  dec(n, preceding)
  assert(0 <= n)
  assert(n < days_in_month(result.year, result.month))
  result.day = n + 1

proc ymd_to_ord*(ymd: YMD): int =
  ##  year, month, day -> ordinal, considering 01-Jan-0001 as day 1.
  days_before_year(ymd.year) + days_before_month(ymd.year, ymd.month) + ymd.day

proc weekday*(year, month, day: int): int =
  ## Day of week, where Monday==0, ..., Sunday==6.  1/1/1 was a Monday. 
  (ymd_to_ord(year, month, day) + 6) mod 7

proc iso_week1_monday*(year: int): int =
  let
    first_day = ymd_to_ord(year, 1, 1)
    first_weekday = (first_day + 6) mod 7
  result = first_day - first_weekday
  if first_weekday > 3:
    result += 7

template raiseValErr(pre: string, i: int, suf: string) =
  raise newException(ValueError, pre & $i & suf)
template raiseValErr(pre: string, i: int) =
  raise newException(ValueError, pre & $i)

type
  YWD* = tuple[
    year, week, day: int
  ]

proc iso_to_ymd*(iso: YWD, ymd: var YMD) =
  ## Year is bounded to 0 < year < 10000 because 9999-12-31 is (9999, 52, 5)
  if iso.year < MINYEAR or iso.year > MAXYEAR:
    raiseValErr "Year is out of range: ", iso.year
  
  if iso.week <= 0 or iso.week >= 53:
    var out_of_range = true
    if iso.week == 53:
      # ISO years have 53 weeks in it on years starting with a Thursday
      # and on leap years starting on Wednesday
      let first_weekday = weekday(iso.year, 1, 1)
      if first_weekday == 3 or (first_weekday == 2 and is_leap(iso.year)):
        out_of_range = false

    if out_of_range:
      raiseValErr "Invalid week: ", iso.week

  if iso.day <= 0 or iso.day >= 8:
    raiseValErr "Invalid day: ", iso.day, " (range is [1, 7])"

  let
    day_1 = iso_week1_monday(iso.year)
    day_offset = (iso.week - 1) * 7 + iso.day - 1
  
  ord_to_ymd(day_1 + day_offset, ymd)

