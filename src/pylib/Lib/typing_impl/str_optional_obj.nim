
import ./optional_obj
export optional_obj
import ../../pystring/strimpl
export strimpl

proc newStrOptionalObj*(x: string): OptionalObj[PyStr] =
  if x.len == 0: newOptionalObj[PyStr]()
  else: newOptionalObj[PyStr](str x)
