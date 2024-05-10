

template fspath*(s: string): string = s
template fspath*(c: char): string = $s

type
  PathLike* = concept self  ## os.PathLike
    self.fspath is string
  CanIOOpenT* = int | PathLike


proc `$`*(p: CanIOOpenT): string =
  ## Mainly for error message
  when p is int: "fd: " & $int(p)
  else: p.fspath
