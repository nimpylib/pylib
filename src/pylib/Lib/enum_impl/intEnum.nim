
import ./enumType




template GenIntEnumMeth*(Self: typedesc; Int = int, genObjMeth = true, genInit = false){.dirty.} =
  bind GenPyEnumMeth
  GenPyEnumMeth(Self, Int, genObjMeth, genInit)
  converter toInt*(self: Self): Int = self.Int

template DeclIntEnumMeth*(Self; Int = int, genObjMeth = true, genInit = false){.dirty.} =
  bind GenIntEnumMeth
  type Self = distinct Int
  GenIntEnumMeth(Self, Int, genObjMeth, genInit)
