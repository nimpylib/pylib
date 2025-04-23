import ./sys
import ../os
const use_fd_functions = (
    os.supports_dir_fd >= {os.open, os.stat, os.unlink, os.rmdir} and
    #(os.open, os.stat, os.unlink, os.rmdir) <= os.supports_dir_fd and
                     os.scandir in os.supports_fd and
                     os.stat in os.supports_follow_symlinks)
when not use_fd_functions:
  import ../stat

type P = string
type
  #Path1Proc = proc (p: string)
  Path1ProcKind = enum
    os_close
    os_rmdir
    os_lstat
    os_open
    os_unlink
    os_path_islink
    os_scandir
  OnExc = proc (
    p: Path1ProcKind,
    fullpath: P,
    exc: ref OSError
  )

type Stack[T] = seq[
  tuple[fun: Path1ProcKind, dirfd: int, path: T, orig_entry: DirEntry[int]]
]
using onexc: OnExc
template isinstance(e; t): bool = e of t
const
  False = false
template pass = discard
template `is`(a, b: Path1ProcKind): bool = a == b
template `is_not`(a, b: Path1ProcKind): bool = a != b
#template `is`(a: DirEntry, b: NoneType): bool = a.isNone
when use_fd_functions:
  import ../../pysugar/pywith
  import std/sequtils
  type List[T] = seq[T]
  template append[T](s: seq[T]; e: T) = s.add e
  template list(s): untyped = toSeq(s)
  const
    None = nil
  proc rmtree_safe_fd_step(stack: var Stack[P]; onexc) =
    # Each stack item has four elements:
    # * func: The first operation to perform: os.lstat, os.close or os.rmdir.
    #   Walking a directory starts with an os.lstat() to detect symlinks; in
    #   this case, func is updated before subsequent operations and passed to
    #   onexc() if an error occurs.
    # * dirfd: Open file descriptor, or None if we're processing the top-level
    #   directory given to rmtree() and the user didn't supply dir_fd.
    # * path: Path of file to operate upon. This is passed to onexc() if an
    #   error occurs.
    # * orig_entry: os.DirEntry, or None if we're processing the top-level
    #   directory given to rmtree(). We used the cached stat() of the entry to
    #   save a call to os.lstat() when walking subdirectories.
    var
      entries: List[DirEntry[int]]
      orig_st: stat_result
      topfd: int
      name: P
      fullname: P
      (fun, dirfd, path, orig_entry) = stack.pop()

    name = if orig_entry is None: path else: orig_entry.name
    try:
        if fun is os_close:
            os.close(dirfd)
            return
        if fun is os_rmdir:
            os.rmdir(name, dir_fd=dirfd)
            return

        # Note: To guard against symlink races, we use the standard
        # lstat()/open()/fstat() trick.
        assert fun is os_lstat
        if orig_entry is None:
            orig_st = os.lstat(name, dir_fd=dirfd)
        else:
            orig_st = orig_entry.stat(follow_symlinks=False)

        fun = os_open  # For error reporting.
        topfd = os.open(name, os.O_RDONLY | os.O_NONBLOCK, dir_fd=dirfd)

        fun = os_path_islink  # For error reporting.
        try:
            if not os.path.samestat(orig_st, os.fstat(topfd)):
                # Symlinks to directories are forbidden, see GH-46010.
                raise newPyOSError("Cannot call rmtree on a symbolic link")
            stack.append((os_rmdir, dirfd, path, orig_entry))
        finally:
            stack.append((os_close, topfd, path, orig_entry))

        fun = os_scandir  # For error reporting.
        with os.scandir(topfd) as scandir_it:
            entries = list(scandir_it)
        for entry in entries:
            fullname = os.path.join(path, entry.name)
            try:
                if entry.is_dir(follow_symlinks=False):
                    # Traverse into sub-directory.
                    stack.append((os_lstat, topfd, fullname, entry))
                    continue
            except FileNotFoundError:
                continue
            except OSError:
                pass
            try:
                unlink(entry.name, dir_fd=topfd)
            except FileNotFoundError:
                continue
            except OSError as err:
                onexc(os_unlink, fullname, err)
    except FileNotFoundError as err:
        if orig_entry is None or fun is os_close:
            err.filename = path
            onexc(fun, path, err)
    except OSError as err:
        if isinstance(err, PyOSError):
          let e = (ref PyOSError)(err)
          e.filename = path
        onexc(fun, path, err)

  # _rmtree_safe_fd
  proc rmtreeImpl[P](path: P, dir_fd: int, onexc) =
    ## Version using fd-based APIs to protect against races
    # While the unsafe rmtree works fine on bytes, the fd based does not.
    #if isinstance(path, bytes):
    when P is_not string:
      let path = os.fsdecode(path)
    var stack: Stack[P] = @[(os_lstat, dir_fd, path, DirEntry[int](None))]
    try:
        while len(stack) != 0:
            rmtree_safe_fd_step(stack, onexc)
    finally:
        # Close any file descriptors still on the stack.
        while len(stack) != 0:
            let (fun, fd, path, _) = stack.pop()
            if fun is_not os_close:
                continue
            try:
                os.close(fd)
            except OSError as err:
                onexc(os_close, path, err)
else:
  when defined(windows): # hasattr(os.stat_result, 'st_file_attributes'):
    proc rmtree_islink(st: stat_result): bool =
        return (stat.S_ISLNK(st.st_mode) or
            (bool(st.st_file_attributes and stat.FILE_ATTRIBUTE_REPARSE_POINT) and
                st.st_reparse_tag == stat.IO_REPARSE_TAG_MOUNT_POINT))
  else:
    proc rmtree_islink(st: stat_result): bool =
        return stat.S_ISLNK(st.st_mode)

  # _rmtree_unsafe
  proc rmtreeImpl[P](path: P, dir_fd: int, onexc) =
    when dir_fd is_not NoneType:
      static:
        raise newException(NotImplementedError, "dir_fd unavailable on this platform")
    var st: stat_result
    try:
        st = os.lstat(path)
    except OSError as err:
        onexc(os_lstat, path, err)
        return
    try:
        if rmtree_islink(st):
            # symlinks to directories are forbidden, see bug #1669
            raise newPyOSError("Cannot call rmtree on a symbolic link")
    except OSError as err:
        onexc(os_path_islink, path, err)
        # can't continue even if onexc hook returns
        return
    proc onerror(err) =
        if not isinstance(err, FileNotFoundError):
            onexc(os_scandir, err.filename, err)
    results = os.walk(path, topdown=False, onerror=onerror, 
      followlinks=os.walk_symlinks_as_files)
    for (dirpath, dirnames, filenames) in results:
        for name in dirnames:
            fullname = os.path.join(dirpath, name)
            try:
                os.rmdir(fullname)
            except FileNotFoundError:
                continue
            except OSError as err:
                onexc(os.rmdir, fullname, err)
        for name in filenames:
            fullname = os.path.join(dirpath, name)
            try:
                os.unlink(fullname)
            except FileNotFoundError:
                continue
            except OSError as err:
                onexc(os.unlink, fullname, err)
    try:
        os.rmdir(path)
    except FileNotFoundError:
        pass
    except OSError as err:
        onexc(os_rmdir, path, err)


proc rmtree*(path: string, ignore_errors=false;
    onerror: OnExc=nil;  # deprecated
    onexc: OnExc = nil,
    dir_fd = -1
  ) =
  sys.audit("shutil.rmtree", path, dir_fd)
  template defonexc(body){.dirty.} =
    onexc = proc (
      fun: Path1ProcKind,
      path: P,
      exc: ref OSError
    ) = body
  var onexc = onexc
  if ignore_errors:
      def_onexc: pass

  elif onerror is None and onexc is None:
      def_onexc:
          raise
  elif onexc is None:
      if onerror is None:
          def_onexc:
              raise
      else:
          # delegate to onerror
          def_onexc:
              #[
              func, path, exc = args
              if exc is None:
                  exc_info = None, None, None
              else:
                  exc_info = type(exc), exc, exc.__traceback__
              ]#
              let exc_info = exc
              onerror(fun, path, exc_info)
  rmtreeImpl(path, dir_fd, onexc)
