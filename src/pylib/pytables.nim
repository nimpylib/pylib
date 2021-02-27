import std/tables

type 
  TableLikeObj* = Table or OrderedTable or CountTable
  TableLikeRef* = TableRef or OrderedTableRef or CountTableRef
  TableLike* = TableLikeObj or TableLikeRef

func `|`*[A, B: TableLike](a: A, b: B): A =
  ## Python-like merge dict operator `print({"a":1} | {"b":2})`,
  ## a new dict is created from `a` and `b`, keys in the second 
  ## operand override keys in the first operand 
  runnableExamples:
    import std/tables

    let d = {"spam": "1", "eggs": "2", "cheese": "3"}.toTable
    let e = {"cheese": "cheddar", "aardvark": "Ethel"}.toTable
    doAssert d | e == {"eggs": "2", "spam": "1", "cheese": "cheddar", "aardvark": "Ethel"}.toTable
    doAssert e | d == {"eggs": "2", "spam": "1", "cheese": "3", "aardvark": "Ethel"}.toTable

    let x = {"a": "0", "b": "1"}.toOrderedTable
    let y = {"c": "2", "b": "1"}.toOrderedTable
    doAssert x | y == {"a": "0", "b": "1", "c": "2"}.toOrderedTable

    let z = {"a": "0", "b": "1"}.toCountTable
    let v = {"c": "2", "b": "1"}.toCountTable
    doAssert z | v  == {"a": "0", "b": "1", "c": "2"}.toCountTable
  
  for key, val in a.pairs:
    result[key] = val
  
  for key, val in b.pairs:
    result[key] = val

# TableRef and similar don't need a "var" to be modified
proc `|=`*[A: TableLikeRef, B: TableLike](a: A, b: B) = 
  ## Python-like in-place dict update operator.
  ## `b` is added into `a`, keys in `b` override same keys from `a`
  runnableExamples:
    import std/tables

    let d = {"spam": "1", "eggs": "2", "cheese": "3"}.newTable
    let e = {"cheese": "cheddar", "aardvark": "Ethel"}.newTable
    d |= e
    doAssert d == {"spam": "1", "eggs": "2", "aardvark": "Ethel", "cheese": "cheddar"}.newTable
  
  for key, val in b.pairs:
    a[key] = val

# Table and similar however need it
func `|=`*[A: TableLikeObj, B: TableLike](a: var A, b: B) = 
  ## Python-like in-place dict update operator.
  ## `b` is added into `a`, keys in `b` override same keys from `a`
  runnableExamples:
    import std/tables

    var d = {"spam": "1", "eggs": "2", "cheese": "3"}.toTable
    let e = {"cheese": "cheddar", "aardvark": "Ethel"}.newTable
    d |= e
    doAssert d == {"spam": "1", "eggs": "2", "aardvark": "Ethel", "cheese": "cheddar"}.toTable

  for key, val in b.pairs:
    a[key] = val
