
template noEmptySep*(sep) =
  when sep is not char:
    if sep.len == 0:
      raise newException(ValueError, "empty separator")

