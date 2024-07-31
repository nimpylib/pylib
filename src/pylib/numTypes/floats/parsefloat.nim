

from std/parseutils import parseFloat
import ./parse_inf_nan
func parsePyFloat*(a: openArray[char], res: var BiggestFloat): int =
  ## Almost the same as parseFloat in std/parseutils
  ## but respects the sign of NaNs
  ##
  ## .. hint:: this does not strip whitespaces, just like parseFloat
  if a.len == 0: return 0
  result = a.parse_inf_or_nan(res)
  if result != 0: return
  result = parseFloat(a, res)
