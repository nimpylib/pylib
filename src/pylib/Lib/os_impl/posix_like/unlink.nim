
import ./unlinkImpl


proc unlink*[T](p: PathLike[T]) = unlinkImpl p

func remove*[T](p: PathLike[T]) =
  ## This function is semantically identical to `unlink`_
  unlinkImpl(p)
