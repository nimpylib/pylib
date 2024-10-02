
include ./common
import ./calendar_utils
import ./init
import ../../timezone_impl/decl
import ../../timedelta_impl/decl

from std/strutils import isDigit  # is_digit
from std/parseutils import parseInt
#import std/strscans  # cannot for openArray[char], but string only


func parse_digits(s: openArray[char], res: var int): int =
  parseInt(s, res)

func parse_digits(s: openArray[char], res: var int, num_digits: int): int =
  parseInt(s.toOpenArray(0, num_digits-1), res)

template parseOr[I: SomeInteger](res: var I; n: int; incVar: var int; destStr; elseDo) =
  when I is_not int:
    var temp: int
    let nparsed = parse_digits(destStr.toOpenArray(incVar, incVar+n-1),
      temp)
    res = I(temp)
  else:
    let nparsed = parse_digits(destStr.toOpenArray(incVar, incVar+n-1),
      res)
  if nparsed != n:
    elseDo
  incVar.inc nparsed

using dtstr: string

func parse_isoformat_date(dtstr; len: int, ymd: var YMD): int =
  ##[Parse the date components of the result of date.isoformat()
     *
 Return codes:
      0:  Success
     -1:  Failed to parse date component
     -2:  Inconsistent date separator usage
     -3:  Failed to parse ISO week.
     -4:  Failed to parse ISO day.
     raises ValueError: Failure in iso_to_ymd]##
  var parsed = 0
  template parseOr(res: var SomeInteger; n: int; elseDo) =
    parseOr(res, n, parsed, dtstr): elseDo
  ymd.year.parseOr(4):
    return -1
  let uses_separator = dtstr[parsed] == '-'
  if uses_separator:
    parsed.inc
  template chkAndSkipSep =
    if uses_separator:
      if dtstr[parsed] != '-':
        return -2
      parsed.inc
  if dtstr[parsed] == 'W':
    # This is an isocalendar-style date string
    parsed.inc
    var ywd: YWD
    ywd.year = ymd.year
    ywd.week.parseOr(2):
      return -3
    if parsed < len:
      chkAndSkipSep
      ywd.day.parseOr(1):
        return -4
    else:
      ywd.day = 1
    
    iso_to_ymd(ywd, ymd)
  else:
    ymd.month.parseOr(2):
      return -1
    chkAndSkipSep
    ymd.day.parseOr(2):
      return -1

type
  HMS = tuple[
    hour, minute, second: int8
  ]
  US = int32

func parse_hh_mm_ss_ff(arr: openArray[char], hms: var HMS, us: var US,
    highIdx = arr.high): int =
  ## Parse [HH[:?MM[:?SS]]][Df{1,}][^\d]* where D is either . or ,
  ## returns 0 if it exceeds the end of the string, judged from `highIdx`
  ## returns 1 if it's not the end

  let hi = arr.high
  # Parse [HH[:?MM[:?SS]]]
  var idx = 0
  template parseOr(res: var SomeInteger, n: int; elseDo) =
    parseOr(res, n, idx, arr): elseDo
  template chkBound =
    if idx >= hi:
      return int(idx <= highIdx)
  template chk2MoreLeft =
    # check there are at least 2 chars to parse
    if idx + 1 > hi:
      return -3
  template eat(attr) =
    parseOr(hms.attr, 2):
      return -3
    chkBound
  template curIsColon: bool = arr[idx] == ':'
  template chkColon =
    if has_separator:
      if not curIsColon:
        return -4  # Malformed time separator
      idx.inc
  chk2MoreLeft
  eat hour
  var has_separator = curIsColon
  if has_separator:
    idx.inc
  chk2MoreLeft
  eat minute
  chkColon
  chk2MoreLeft
  eat second

  # Parse fractional components
  if arr[idx] == '.' or arr[idx] == ',':
    idx.inc

  let
    len_remains = hi + 1 - idx
    to_parse = min(len_remains, 6)
  var i = -1
  let parsed = parse_digits(arr.toOpenArray(idx, arr.high), i, to_parse)
  if  parsed != to_parse:
    return -3
  {.push overflowChecks: off, boundChecks: off, rangeChecks: off.}
  us = US(i)  # we know there will be no overflow
  const correction = [US(100000), 10000, 1000, 100, 10]
  if to_parse < 6:
    # append 0 to end of int
    us = us *% correction[to_parse - 1]
  {.pop.}
  while idx <= hi and is_digit(arr[idx]):
    idx.inc
  return int(idx <= highIdx)

func parse_isoformat_time(dtstr: openArray[char]; dtlen: int,
    hms: var HMS, us: var US, tzoffset: var int, tzmicrosecond: var US): int =
  let hi = dtlen - 1
  var
    tzinfo_pos = dtlen  # init with an invalid pos
    tzinfo_sign_char: char
  for i, c in dtstr:
    if c == 'Z' or c == '+' or c == '-':
      tzinfo_pos = i
      tzinfo_sign_char = c
  var rv = parse_hh_mm_ss_ff(
    dtstr.toOpenArray(0, tzinfo_pos-1), hms, us,
    highIdx = hi
  )

  if rv < 0:
    return rv
  elif tzinfo_pos == dtlen:
    # We know that there's no time zone, so if there's stuff at the
    # end of the string it's an error.
    if rv == 1:
      return -5
    else:
      return 0
  # Special case UTC / Zulu time.
  if tzinfo_sign_char == 'Z':
    tzoffset = 0
    tzmicrosecond = 0
    if tzinfo_pos != hi:
      return -5
    else:
      return 1
  let tzsign = US(if tzinfo_sign_char == '-': -1 else: 1)
  tzinfo_pos.inc
  var tz_hms: HMS
  rv = parse_hh_mm_ss_ff(
    dtstr.toOpenArray(tzinfo_pos, hi),
    tz_hms, tzmicrosecond)
  type Offset = typeof(tzoffset)
  tzoffset = tzsign * ((tz_hms.hour.Offset * 3600) + (tz_hms.minute.Offset * 60) + tz_hms.second.Offset)
  tzmicrosecond *= tzsign

  return if bool(rv): -5 else: 1

func find_isoformat_datetime_separator(dtstr): int =
  ##[The valid date formats can all be distinguished by characters 4 and 5
and further narrowed down by character
which tells us where to look for the separator character.
Format    |  As-rendered |   Position
---------------------------------------
%Y-%m-%d  |  YYYY-MM-DD  |    10
%Y%m%d    |  YYYYMMDD    |     8
%Y-W%V    |  YYYY-Www    |     8
%YW%V     |  YYYYWww     |     7
%Y-W%V-%u |  YYYY-Www-d  |    10
%YW%V%u   |  YYYYWwwd    |     8
%Y-%j     |  YYYY-DDD    |     8
%Y%j      |  YYYYDDD     |     7

Note that because we allow *any* character for the separator, in the
case where character 4 is W, it's not straightforward to determine where
the separator is — in the case of YYYY-Www-d, you have actual ambiguity,
e.g. 2020-W01-0000 could be YYYY-Www-D0HH or YYYY-Www-HHMM, when the
separator character is a number in the former case or a hyphen in the
latter case.

The case of YYYYWww can be distinguished from YYYYWwwd by tracking ahead
to either the end of the string or the first non-numeric character —
since the time components all come in pairs YYYYWww#HH can be
distinguished from YYYYWwwd#HH by the fact that there will always be an
odd number of digits before the first non-digit character in the former
case.]##
  let len = dtstr.len  # in byte
  const
    date_separator = '-'
    week_indicator = 'W'
  if len == 7:
    return 7
  if dtstr[4] == date_separator:
    # YYYY-???
    if dtstr[5] == week_indicator:
      # YYYY-W?
      if len < 8:
        return -1
      
      if len > 8 and dtstr[8] == date_separator:
        # YYYY-Www-D (10) or YYYY-Www-HH (8)
        if len == 9: return -1
        if len > 10 and is_digit(dtstr[10]):
          # This is as far as we'll try to go to resolve the
          # ambiguity for the moment — if we have YYYY-Www-##, the
          # separator is either a hyphen at 8 or a number at 10.
          # We'll assume it's a hyphen at 8 because it's way more
          # likely that someone will use a hyphen as a separator
          # than a number, but at this point it's really best effort
          # because this is an extension of the spec anyway.
          return 8
        return 10
      else:
        # YYYY-Www (8)
        return 8
    else:
      # YYYY-MM-DD (10)
      return 10
  else:
    # YYYY???
    if dtstr[4] == week_indicator:
      # YYYYWww (7) or YYYYWwwd (8)
      var idx = 7
      while idx < len:
        if not is_digit(dtstr[idx]):
          idx.inc
          break
        idx.inc
      if idx < 9:
        return idx
      if idx mod 2 == 0:
        # If the index of the last number is even, it's YYYYWww
        return 7
      else:
        return 8
    else:
      # YYYYMMDD (8)
      return 8

proc tzinfo_from_isoformat_results(rv: int, tzoffset: int, tz_usecond: US): tzinfo =
  if rv == 1:
    # Create a timezone from offset in seconds (0 returns UTC)
    if tzoffset == 0:
      return UTC
    let delta = newTimedelta(0, tzoffset, tz_usecond, normalize=false)
    result = newPyTimezone(delta)
  else:
    result = TzNone

import ./isoformat
proc datetime_fromisoformat*(dtstr): datetime =
  let len = dtstr.len

  template invalid_string_error =
    raise newException(ValueError, "Invalid isoformat string: " & dtstr.repr)
  # XXX: we always use Nim's string,
  # so we can just skip encoding issues about surrogate characters,
  # no need to perform `_sanitize_isoformat_str`
  # we just need to check the length:
  if len < 7:
    invalid_string_error

  let separator_location = find_isoformat_datetime_separator(dtstr)
  var
    ymd: YMD
    hms: HMS
    microsecond: US
    tzoffset: int
    tzusec: US
  # date runs up to separator_location
  var rv = parse_isoformat_date(dtstr, separator_location, ymd)

  if rv == 0 and len > separator_location:
    # In UTF-8, the length of multi-byte characters is encoded in the MSB
    let ci = dtstr[separator_location].int
    let off = separator_location + (
      # get UTF-8 length from MSB  (maybe use `unicode.graphemeLen`)
      if (ci and 0x80) == 0: 1
      else:
        case (ci and 0xf0)
        of 0xe0: 3
        of 0xf0: 4
        else: 2
    )
    let nlen = len - off
    rv = parse_isoformat_time(dtstr.toOpenArray(off, dtstr.high), nlen, hms, microsecond, 
      tzoffset, tzusec)
  if rv < 0:
    invalid_string_error
  let tzinfo = tzinfo_from_isoformat_results(rv, tzoffset, tzusec)
  result = datetime(
    ymd.year, ymd.month, ymd.day,
    hms.hour, hms.minute, hms.second, microsecond,
    tzinfo = tzinfo)

