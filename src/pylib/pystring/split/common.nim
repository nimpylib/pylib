
import ../[
  strimpl]
export strimpl

# `PREALLOC_SIZE` (unicodeobject.c L17, used in L59) uses 12 as min len.
const DefSplitCap* = 12

# split.h PREALLOC_SIZE L17
template PREPARE_CAP*(maxcount): int =
  ## `maxcount` shall be Natural
  min(DefSplitCap, maxcount)

# unicodeobject.c L9907
func norm_maxsplit*(maxsplit: int, str_len, sep_len: int): int =
  if maxsplit < 0:
    result = if sep_len == 0: 0 else: (str_len div sep_len) + 1
    if result < 0: result = str_len
