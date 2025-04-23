
import ./unlinkImpl


proc unlink*[T](p: PathLike[T]) =
  sys.audit("os.remove", p, -1)
  unlinkImpl p

proc remove*[T](p: PathLike[T]) =
  ## This function is semantically identical to `unlink`_
  unlink(p)
