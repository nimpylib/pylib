
import ../../isX

template isInfinite*(f: SomeFloat): bool =
  bind isinf
  isinf(f)
