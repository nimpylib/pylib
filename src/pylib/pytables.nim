import tables

type TableLike* = Table or OrderedTable or CountTable

func `|`*[A, B: TableLike](a: A, b: B): A =
  ## Mimic Python 3.9+ merge dicts operator `print({"a":1} | {"b":2})`,
  ## `b` is merged into `a` like Python, without duplicate keys.
  runnableExamples:
    import tables
    let a = {"a": "0", "b": "1"}.toTable
    let b = {"c": "2", "b": "1"}.toTable
    doAssert a | b == {"b": "1", "c": "2", "a": "0"}.toTable
    let x = {"a": "0", "b": "1"}.toOrderedTable
    let y = {"c": "2", "b": "1"}.toOrderedTable
    doAssert x | y == {"a": "0", "b": "1", "c": "2"}.toOrderedTable
    let z = {"a": "0", "b": "1"}.toCountTable
    let v = {"c": "2", "b": "1"}.toCountTable
    doAssert z | v  == {"a": "0", "b": "1", "c": "2"}.toCountTable
  for key, val in a.pairs:
    if not result.hasKey key: result[key] = val
  for key, val in b.pairs:
    if not result.hasKey key: result[key] = val
