 
template getsizeof*(x): int =
  mixin sizeof
  sizeof(x)

template getsizeof*(x; default: int): int =
  ## may be used when `sizeof(x)` is a compile-error
  ## e.g. `func sizeof(x: O): int{.error.}` for `O`
  mixin sizeof
  when compiles(sizeof(x)): sizeof(x)
  else: default
