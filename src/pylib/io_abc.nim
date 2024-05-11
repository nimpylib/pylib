
import ./pystring/strimpl
import ./pybytes/bytesimpl

template fspath*(s: string): PyStr = bind str; str s
template fspath*(c: char): PyStr = bind str; str s

type
  PathLike* = concept self  ## os.PathLike
    self.fspath is PyStr|PyBytes
  CanIOOpenT* = int | PathLike


proc `$`*(p: CanIOOpenT): string =
  ## Mainly for error message
  when p is int: "fd: " & $int(p)
  else: $p.fspath
