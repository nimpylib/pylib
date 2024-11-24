
import std/tables

type
  dict*[K, V] = ref object
    data: OrderedTable[K, V]
  PyDict*[K, V] = dict[K, V]

func toNimTable*[K, V](self: PyDict[K,V]): var OrderedTable[K, V] = self.data

template newPyDict*[K, V](x: int): untyped =
  bind initOrderedTable
  PyDict[K, V](data: initOrderedTable[K, V](x))

template newPyDict*[K, V](x: openArray[(K, V)] = []): untyped =
  ## zero or one arg
  ## shall support `[]`, `{k:v, ...}`, `@[(k, v),...]`
  bind toOrderedTable
  PyDict[K, V](data: toOrderedTable[K, V](x))

{.push deprecated: "use newPyDict, to be removed since 0.10".}
template newPyDictImpl*[K, V](x: int): untyped =
  bind newPyDict
  newPyDict(x)

template newPyDictImpl*[K, V](x: openArray[(K, V)] = []): untyped =
  bind newPyDict
  newPyDict(x)
{.pop.}

proc getOrDefault*[A, B](t: PyDict[A, B], key: A): B =
  ## inner. used to impl get(key, default)
  t.toNimTable.getOrDefault key
func emptyPyDict*[K, V](): PyDict[K, V] = newPyDictImpl[K, V]([])
