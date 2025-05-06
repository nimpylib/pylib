
template una(dest, src){.dirty.} =
  template dest*[I: SomeInteger](a: I): I = src(a)
template bin(dest, src, idest){.dirty.} =
  template dest*[I: SomeInteger](a, b: I): I = src(a, b)
  proc idest*[I: SomeInteger](a: var I, b: I) = a = src(a, b)

template exportIntBitOps*{.dirty.} =
  ## 
  ## .. warning:: `<<` causes overflow silently.
  ##  Yet Python's int never overflows.
  ## Currently `shr` is also `arithm shr`, but it used to be `logic shr`
  bind una, bin
  una `~`,  `not`
  bin `^`,  `xor`, `^=`
  bin `&`,  `and`, `&=`
  bin `|`,  `or`,  `|=`
  bin `<<`, `shl`, `<<=`
  bin `>>`, `shr`, `>>=`

