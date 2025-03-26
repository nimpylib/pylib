
import ./enumType




template GenIntEnumMeth*(Self: typedesc; Int = int){.dirty.} =
  bind GenPyEnumMeth
  GenPyEnumMeth(Self, Int)
  converter toInt*(self: Self): Int = self.Int

template DeclIntEnumMeth*(Self; Int = int){.dirty.} =
  bind GenIntEnumMeth
  type Self = distinct Int
  GenIntEnumMeth(Self, Int)
