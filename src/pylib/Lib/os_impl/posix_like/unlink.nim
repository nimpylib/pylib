
import ./unlinkImpl

template unlinkBody(p) =
  if not unlinkImpl(p):
    p.raiseExcWithPath()

proc unlink*[T](p: PathLike[T]) = unlinkBody p

func remove*[T](p: PathLike[T]) =
  ## This function is semantically identical to `unlink`_
  unlinkBody(p)
