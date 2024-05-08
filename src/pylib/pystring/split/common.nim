
import ../[
  strimpl]
export strimpl

# `PREALLOC_SIZE` (unicodeobject.c L17, used in L59) uses 12 as min len.
const DefSplitCap* = 12

template PREPARE_CAP*(maxcount): int =
  # split.h PREALLOC_SIZE L17
  min(DefSplitCap, maxcount)
