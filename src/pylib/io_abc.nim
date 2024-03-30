

template fspath*(s: string) = s
template fspath*(c: char) = $s

type
  PathLike* = concept self
    self.fspath() is string
  CanIOOpenT* = int | PathLike


