
import std/tables

type
  dict*[K, V] = ref object
    data: OrderedTable[K, V]
  PyDict*[K, V] = dict[K, V]

func toNimTable*[K, V](self: PyDict[K,V]): var OrderedTable[K, V] = self.data

template newPyDictImpl*[K, V](x: int): untyped =
  bind initOrderedTable
  PyDict[K, V](data: initOrderedTable[K, V](x))

template newPyDictImpl*[K, V](x: openArray[(K, V)] = []): untyped =
  ## zero or one arg
  ## shall support `[]`, `{k:v, ...}`, `@[(k, v),...]`
  bind toOrderedTable
  PyDict[K, V](data: toOrderedTable[K, V](x))

proc getOrDefault*[A, B](t: PyDict[A, B], key: A): B =
  ## inner. used to impl get(key, default)
  t.toNimTable.getOrDefault key
func emptyPyDict*[K, V](): PyDict[K, V] = newPyDictImpl[K, V]([])
