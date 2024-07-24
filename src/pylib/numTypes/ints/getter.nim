

import std/bitops
import ./decl
import ../reimporter

template is_integer*(_: NimInt): bool{.pysince(3,12).} = true
template as_integer_ratio*(self: NimInt): (NimInt, NimInt){.pysince(3,8).} = (self, 1)


template bit_length*(self: NimInt): NimInt =
  bind fastLog2, abs
  1 + fastLog2 abs(self)

template bit_count*(self: NimInt): NimInt{.pysince(3,10).} =
  self.countSetBits()

template conjugate*(self: NimInt): NimInt = self
