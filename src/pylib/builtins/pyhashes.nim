
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
hashable tuple
hashable proc

proc hash*(x: PyComplex): int = toInt hashes.hash(x.toNimComplex)
proc hash*(x: PyStr|PyBytes): int = toInt hashes.hash($x)

const unhashErr = "TypeError: unhashable type: "
template unhashable(typ){.dirty.} =
  proc hash*(x: typ): int{.error: unhashErr & $typ.}

unhashable PyList
unhashable PyDict
unhashable PySet
