
import ./pystring/strimpl
import ./pybytes/bytesimpl

func fspath*(s: string): PyStr = str s
func fspath*(c: char): PyStr = str c

type
  FsPath = PyStr|PyBytes
  PathLike*[T: FsPath] = concept self  ## os.PathLike
    T  # XXX: still to prevent wrong compiler hint: `T is not used`
    self.fspath is T
  CanIOOpenT*[T] = int | PathLike[T]


template mapPathLike*[T](s: PathLike[T], nimProc): T =
  when T is PyStr: str nimProc s.fspath
  else: bytes nimProc s.fspath
template mapPathLike*[T](nexpr): T =
  when T is PyStr: str nexpr
  else: bytes nexpr


func `$`*(p: PathLike): string =
  $p.fspath


proc `$`*(p: CanIOOpenT): string =
  ## Mainly for error message
  when p is int: "fd: " & $int(p)
  else: $p

