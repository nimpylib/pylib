## asctime that returns string

import std/times

template asctimeImpl*(result: string, dt: DateTime) =
  result.add dt.format "ddd MMM "
  var day = dt.format "dd "
  if day[0] == '0': day[0] = ' '
  result.add day
  result.add dt.format "HH:MM:ss uuuu"

func asctime*(dt: DateTime): string =
  asctimeImpl(result, dt)
