
import ../pystring/strimpl
import ./list

using o: object|tuple|ref object
template fieldPairs[T](r: ref T): untyped = r[].fieldPairs

iterator dirImpl*(o): string =
  for i, _ in o.fieldPairs: yield i

iterator dir*(o): PyStr =
  for i in o.dirImpl: yield i

proc dirImpl*(o): seq[string] =
  for i in o.dirImpl: result.add i

proc dir*(o): PyList[PyStr] =
  result = list[PyStr]()
  for i in o.dir: result.append i
