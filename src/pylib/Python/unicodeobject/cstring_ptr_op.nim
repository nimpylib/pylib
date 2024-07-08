
import ./ptr_types

type IndexType = int|int64|csize_t

template `+`*[I: IndexType](s: cstring, i: I): cstring =
  cast[cstring](cast[I](s)+i)

template inc*(s: cstring; i=1) = s = s+i

template `-`*(a, b: cstring): ptrdiff_t =
  cast[ptrdiff_t](a) - cast[ptrdiff_t](b)

template `<%`*(a, b: cstring): bool =
  cast[int](a) < cast[int](b)

template `<=%`*(a, b: cstring): bool =
  cast[int](a) <= cast[int](b)
