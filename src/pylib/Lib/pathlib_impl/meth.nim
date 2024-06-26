

import ./types

using self: types.Path

func `/`*(head: string, tail: Path): Path = Path(head) / tail
func `/`*(head: Path, tail: string): Path = head / Path(tail)

func joinpath*[P: string|Path](self; pathsegments: varargs[P]): Path =
  result = self
  for i in pathsegments:
    result = result / i
