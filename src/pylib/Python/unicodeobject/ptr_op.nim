
import ./ptr_types
type IndexType = int|int64|csize_t

template `+`*[I: IndexType; T](s: ptr T, i: I): ptr T =
  cast[ptr T](cast[I](s)+i)

template inc*[T](s: ptr T; i=1) = s = s+i

template `-`*[T](a, b: ptr T): ptrdiff_t =
  cast[ptrdiff_t](a) - cast[ptrdiff_t](b)

template `<%`*[T](a, b: ptr T): bool =
  cast[int](a) < cast[int](b)

template `<=%`*[T](a, b: ptr T): bool =
  cast[int](a) <= cast[int](b)

template `[]`*[I: IndexType; T](p: ptr T; i: I): T =
  (p+i)[]

