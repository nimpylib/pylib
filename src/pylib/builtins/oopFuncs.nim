

import std/macros

macro wrapop(op: static[string], obj, class_or_tuple): bool =
  if class_or_tuple.kind == nnkTupleConstr:
    template iOr(a,b): untyped = infix(a,"or",b)
    result = infix(obj, op, class_or_tuple[0])
    for i in 1..<class_or_tuple.len:
      let kid = class_or_tuple[i]
      result = iOr(result, infix(obj, op, kid))
  else:
    result = infix(obj, op, class_or_tuple)

template isinstance*(obj, class_or_tuple): bool =
  runnableExamples:
    assert isinstance(1, int)
    assert isinstance(1.0, (int, float))
    assert not isinstance('c', bool)
  wrapop "is", obj, class_or_tuple

template issubclass*(obj, class_or_tuple): bool =
  wrapop "of", obj, class_or_tuple
  
  