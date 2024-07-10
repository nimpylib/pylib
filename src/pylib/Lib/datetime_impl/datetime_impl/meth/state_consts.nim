
import ./init

import ../../timezone_impl/decl
template utc_timezone*: timezone =
  bind UTC
  UTC
# st = GET_CURRENT_STATE(current_mod); CONST_EPOCH(st)
let CONST_EPOCH* = datetime(
          1970, 1, 1, 0, 0, 0, 0, utc_timezone, fold=0)
