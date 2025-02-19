
when compileOption"threads":
  template allocImpl(T, s): untyped = cast[ptr T](allocShared(s))
  template pyfree(p) = freeShared p
else:
  template allocImpl(T, s) = cast[ptr T](alloc(s))
  template pyfree(p) = free p
export pyfree

template pyalloc*[T](s): ptr T = allocImpl(T, s)
template pyallocStr*(s): cstring = cast[cstring](pyalloc[cchar](s))
template pyfreeStr*(p) = pyfree cast[ptr cchar](p)

template memcpy*[T](a, b: ptr T, n: int) = copyMem(a, b, n)
