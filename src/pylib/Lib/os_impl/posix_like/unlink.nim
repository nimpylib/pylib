
import std/os
import ./unlinkImpl

template unlinkBody(p) =
  if not unlinkImpl(p):
    raiseOSError(osLastError(), $p)

func unlink*[T](p: PathLike[T]) = unlinkBody p

func remove*[T](p: PathLike[T]) =
  ## This function is semantically identical to `unlink`_
  unlinkBody(p)
