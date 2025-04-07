##[
Where a function has a single filename, such as open() or some
of the os module functions, PyErr_SetFromErrnoWithFilename() is
called, giving a third argument which is the filename. But, so
that old code using in-place unpacking doesn't break, e.g.:

except OSError, (errno, strerror):

we hack args so that it only contains two items. This also
means we need our own __str__() which prints out the filename
when it was supplied.

(If a function has two filenames, such as rename(), symlink(),
or copy(), PyErr_SetFromErrnoWithFilenameObjects() is called,
which allows passing in a second filename.)
]##

import ./[types, errmap, oserror_str]
when defined(windows):
  import ./PC_errmap
type
  OSErrorArgs*[third: string|int] = tuple
    errno: cint
    strerror: string
    filename: third
    winerror: cint
    filename2: string
template PyNumber_Check(x): bool = x is int
template PyNumber_AsSsize_t(x, _): int = x

template parseOSErrorArgs(args: var OSErrorArgs) =
  ## Parses arguments for OSError construction
  ## Returns tuple containing errno, strerror, filename, filename2, and winerror (on Windows)
  ## Note: This function doesn't cleanup on error, the caller should
  when defined(windows):
    args.winerror = winerror
    if args.winerror != 0:
      args.errno = winerror_to_errno(args.winerror)

template oserror_use_init*[E: PyOSError](self): bool =
  ##[
    When __init__ is defined in an OSError subclass, we want any
    extraneous argument to __new__ to be ignored.  The only reasonable
    solution, given __new__ takes a variable number of arguments,
    is to defer arg parsing and initialization to __init__.

    But when __new__ is overridden as well, it should call our __new__
    with the right arguments.

    (see http://bugs.python.org/issue12555#msg148829 )
  ]##
  compiles(
    (cast[ref E](self)).init(0, ""))

proc init*[E: PyOSError](self: ref E, args: OSErrorArgs) =
  when E is BlockingIOError:
    if PyNumber_Check(args.filename):
      self.characters_written = PyNumber_AsSsize_t(args.filename, ValueError)
    else:
      self.filename = args.filename
      self.filename2 = args.filename2
  self.errno = args.errno
  self.strerror = args.strerror
  when defined(windows):
    self.winerror = args.winerror

proc OSError_new*[E: PyOSError](useWinError: bool, myerrno: cint, strerr: string,
    filename: string|int = "", winerror: cint = 0, filename2 = "", fillMsg: static[bool] = true): ref PyOSError =
  ## may returns a subclass of OSError
  type Third = typeof(filename)
  var args: OSErrorArgs[Third] = (myerrno, strerr, filename, winerror, filename2)
  var newtype = proc (): ref PyOSError = new E
  let use_init = oserror_use_init[E](result)
  if not use_init:
    if useWinError:
      parseOSErrorArgs(args)
    when E is PyOSError:
      newtype = errnomap.getOrDefault(args.errno, default_oserror)
  result = newtype()
  result.characters_written = -1

  if not use_init:
    result.init(args)

  when fillMsg:
    result.msg = $result

