## used by ./int_bytes

import ./decl
from ./getter import bit_length
export bit_length

template newInt*(): NimInt = NimInt(0)
template getSize*(self: NimInt): int = sizeof(NimInt) # sizeof cannot be overloaded
template fitLen*(_: var NimInt, nbyte: int): bool = nbyte <= sizeof(NimInt)
