## asctime that returns string

import std/times

template asctimeImpl*(result: string, dt: DateTime) =
  result.add dt.format "ddd MMM "
  # %2d
  let day = dt.monthday.int
  if day < 10:
    result.add ' ' 
  result.add $day
  result.add ' '
  result.add dt.format "HH:mm:ss uuuu"

func asctime*(dt: DateTime): string =
  asctimeImpl(result, dt)
