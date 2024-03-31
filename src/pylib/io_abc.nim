

template fspath*(s: string): string = s
template fspath*(c: char): string = $s

type
  PathLike* = concept self  ## os.PathLike
    self.fspath is string
  CanIOOpenT* = int | PathLike


