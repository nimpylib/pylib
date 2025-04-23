

import ./common
import ./listcommon
import ./posix_like/scandirImpl
import ./path

type
  OnErrorCb* = proc (e: ref PyOSError)
  WalkTup[T] = tuple[dirpath: T, dirnames, filenames: PyList[T]]
  ## used for type conversion
  
  # We use distinct to hook `repr`
  WalkRes*[T] = distinct WalkTup[T]
converter toTup*[T](self: WalkRes[T]): WalkTup[T] =
  ## converts to `tuple[T, list[T], list[T]]`
  WalkTup[T](self)
template `[]`*[T](self: WalkRes[T], i: static int): untyped =
  bind WalkTup
  const idx =
    if i < 0: 3 - i
    else: i
  (WalkTup[T](self))[idx]
const sep = ", "
template repr*[T](self: WalkRes[T]): string =
  ## returns `(xx, [xx], [xx])` as Python's
  bind sep
  var result = "("
  result.add self[0].repr & sep
  result.add self[1].repr & sep
  result.add self[2].repr & ')'
  result
template `$`*[T](self: WalkRes[T]): string = self.repr

iterator reversed[T](ls: PyList[T]): T =
  for i in countdown(len(ls)-1, 0):
    yield ls[i]

const
  shallIgnore*: OnErrorCb = nil
  # we do not use PyBool on pylib's os
  True = true
  False = false

type
  UnionItem[A, B] = object
    case isA: bool
    of true:  a: A
    of false: b: B
  UnionList[A, B] = PyList[UnionItem[A, B]]
proc newUnionList[A, B](): UnionList[A, B] = list[UnionItem[A, B]]() 

func isinstance[A,B](i: UnionItem[A, B], t: typedesc[A|B]): bool =
  when t is A: i.isA
  else: not i.isA

template append[A, B](ls: UnionList[A, B], x: A) =
  ls.append UnionItem[A, B](isA: true, a: x)
template append[A, B](ls: UnionList[A, B], x: B) =
  ls.append UnionItem[A, B](isA: false, b: x)

type ScanDir[T] = iterator (path: T): DirEntry[T]{.closure.}

# translated from CPython-3.13-alpha/Lib/os.py L284
iterator walk*[T](top: PathLike[T], topdown=True,
      onerror=shallIgnore, followlinks=False): WalkRes[T] =
    sys.audit("os.walk", top, topdown, onerror, followlinks)
    var stack = newUnionList[T, WalkRes[T]]()
    stack.append(fspath(top))
      
    while len(stack) != 0:
        let utop = stack.pop()
        if isinstance(utop, WalkRes[T]):
            yield utop.b
            continue
        let top = utop.a
        var
          dirs = list[T]()
          nondirs = list[T]()
          walk_dirs = list[T]()

        # We may not have read permission for top, in which case we can't
        # get a list of the files the directory contains.
        # We suppress the exception here, rather than blow up for a
        # minor reason when (say) a thousand readable directories are still
        # left to visit.
        var scandir_it: ScanDir[T] = scandirIter

        var cont = False
        #with scandir_it:
        when True:
            while True:
                var entry: DirEntry[T]
                try:
                    entry = scandir_it(top)
                    if scandir_it.finished():
                      break
                except OSError as error:
                    if onerror != shallIgnore:
                        onerror(newPyOSError(error.errorCode.cint, error.msg))
                    cont = True
                    break
                let isdir =
                  try:
                    entry.is_dir()
                  except OSError:
                    # If is_dir() raises an OSError, consider the entry not to
                    # be a directory, same behaviour as os.path.isdir().
                    False

                if is_dir:
                    dirs.append(entry.name)
                else:
                    nondirs.append(entry.name)

                if not topdown and is_dir:
                    # Bottom-up: traverse into sub-directory, but exclude
                    # symlinks to directories if followlinks is False
                    let walk_into =
                      if followlinks:
                        True
                      else:
                        let issymlink =
                          try:
                            entry.is_symlink()
                          except OSError:
                            # If is_symlink() raises an OSError, consider the
                            # entry not to be a symbolic link, same behaviour
                            # as os.path.islink().
                            False
                        not is_symlink

                    if walk_into:
                        walk_dirs.append(entry.path)
        if cont:
            continue

        if topdown:
            # Yield before sub-directory traversal if going top down
            yield WalkRes[T]((top, dirs, nondirs))
            # Traverse into sub-directories
            for dirname in reversed(dirs):
                let new_path = join(top, dirname)
                # bpo-23605: os.path.islink() is used instead of caching
                # entry.is_symlink() result during the loop on os.scandir() because
                # the caller can replace the directory entry during the "yield"
                # above.
                if followlinks or not islink(new_path):
                    stack.append(new_path)
        else:
            # Yield after sub-directory traversal if going bottom up
            stack.append(WalkRes[T]((top, dirs, nondirs)))
            # Traverse into sub-directories
            for new_path in reversed(walk_dirs):
                stack.append(new_path)

iterator walk*[T](top: PathLike[T], topdown=True,
      onerror=None, followlinks=False): WalkRes[T] =
  for i in walk(top, topdown, shallIgnore, followlinks): yield i


type WalkIterator[T] = ref object
  iter: iterator(): WalkRes[T]{.closure.}
proc walk*[T](top: PathLike[T], topdown=True,
      onerror=shallIgnore, followlinks=False): WalkIterator[T] =
  new result
  result.iter = iterator(): WalkRes[T] =
    for i in walk(top, topdown, onerror, followlinks): yield i
proc walk*[T](top: PathLike[T], topdown=True,
      onerror=None, followlinks=False): WalkIterator[T] =
  new result
  result.iter = iterator(): WalkRes[T] =
    for i in walk(top, topdown, onerror, followlinks): yield i

