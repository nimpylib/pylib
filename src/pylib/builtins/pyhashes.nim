
import std/hashes
import ./list, ./dict, ./set
import ./complex
import ../pystring/strimpl
import ../pybytes/bytesimpl

template toInt(h: Hash): int = int(h)
template asIs[T](x: T): T = x
template hashable(typ; cvt: untyped = asIs){.dirty.} =
  # TODO: fix(py): ref Python/pyhash.c
  proc hash*(x: typ): int =
    ## .. warning:: this uses `std/hashes` algorithm,
    ##   which differs from CPython's.
    ##   Also, `a==b` <=> `hash(a) == hash(b)`,
    ##   where a, b are of *different* types, is not guaranteed.
    toInt hashes.hash(cvt(x))

hashable int
hashable float
hashable tuple
hashable proc

hashable PyTComplex, toNimComplex
hashable PyStr|PyBytes, `$`

const unhashErr = "TypeError: unhashable type: "
template unhashable(typ; typRepr){.dirty.} =
  proc hash*(x: typ): int{.error: unhashErr & typRepr}

unhashable PyList, "'list'"
unhashable PyDict, "'dict'"
unhashable PySet, "'set'"
