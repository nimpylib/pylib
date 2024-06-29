
import std/hashes
import ./list, ./dict, ./set
import ./complex
import ../pystring/strimpl
import ../pybytes/bytesimpl

template toInt(h: Hash): int = int(h)
template hashable(typ){.dirty.} =
  proc hash*(x: typ): int = toInt hashes.hash(x)

hashable int
hashable float
hashable PyComplex
hashable PyStr
hashable PyBytes
hashable tuple
hashable proc

const unhashErr = "TypeError: unhashable type: "
template unhashable(typ){.dirty.} =
  proc hash*(x: typ): int{.error: unhashErr & $typ.}

unhashable PyList
unhashable PyDict
unhashable PySet
