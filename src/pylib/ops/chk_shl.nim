
func shlByMul[I: SomeInteger](a, b: I): I{.used.} =
  result = a
  for _ in 1..b:
    result *= 2

func checkedShl*[I: SomeInteger](a, b: I): I =
  when compileOption("overflowChecks"): shlByMul(a, b)
  else: `shl`(a, b)
