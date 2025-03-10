## a ChainMap version accepting 2 Tables
import std/tables

type
  ChainMap*[K, V] = object
    a, b: Table[K, V]

proc initChainMap*[K, V](a, b: Table[K, V]): ChainMap[K, V] =
  ChainMap(a: a, b: b)

proc `[]`*[K, V](self: ChainMap[K, V], k: K): V =
  if self.a.hasKey(k): self.a[k]
  else: self.b[k]

proc contains*[K, V](self: ChainMap[K, V], k: K): bool =
  self.a.contains(k) or self.b.contains(k)
