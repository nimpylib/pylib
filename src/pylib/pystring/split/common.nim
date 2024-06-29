
import ../strimpl
export strimpl
import ../../stringlib/split/common as ncommon
export ncommon
import ../consts

func ISSPACE*(s: PyStr, pos: int): bool =
  ## Checks unicode space at unicode char's `pos`
  s.runeAtPos(pos) in unicodeSpaces



