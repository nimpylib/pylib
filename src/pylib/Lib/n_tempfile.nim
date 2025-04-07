
import std/os
import std/random
import std/options

import ./n_os

when defined(js): {.error: "pylib tempfile not support JS currently".}
import ./io

const
  True = true
  False = false
const
  TMP_MAX* = 10000

type RandomNameSequence = object
  rng_pid: int
  rng: Rand

var name_sequence{.threadvar.}: RandomNameSequence

const RandChars = "abcdefghijklmnopqrstuvwxyz0123456789_"

proc initRandomNameSequence(self: var RandomNameSequence) =
  let cur_pid = getCurrentProcessId()
  if cur_pid != self.rng_pid:
    self.rng = initRand()
    self.rng_pid = cur_pid

iterator items(self: var RandomNameSequence, times: int): string =
  self.initRandomNameSequence()
  for _ in 1..times:
    var letters = newString(8)
    for i in 0 ..< 8:
      let c = self.rng.sample(RandChars)
      letters[i] = c
    yield letters

const templ* = "tmp"  # Py's `tempfile.template`

proc mktemp*(suffix="", prefix=templ, dir = "", checker=fileExists): string =
  ## User-callable function to return a unique temporary file/dir name.  The
  ##  file/dir is not created.
  for name in name_sequence.items(times=TMP_MAX):
    let file = dir / prefix & name & suffix
    if not checker file:
      return file
  raise newException(OSError, "No usable temporary filename found")


proc candidate_tempdir_list(): seq[string] =
    ##[Generate a list of candidate temporary directories which
    _get_default_tempdir will try.]##

    # First, try the environment.
    for envname in ["TMPDIR", "TEMP", "TMP"]:
        let dirname = getenv(envname)
        if dirname.len > 0: result.add dirname

    # Failing that, try OS-specific locations.
    when n_os.name == "nt":
        result.add [ expandTilde(r"~\AppData\Local\Temp"),
                     getenv("SYSTEMROOT")/"Temp",
                     r"c:\temp", r"c:\tmp", r"\temp", r"\tmp" ]
    else:
        result.add [ "/tmp", "/var/tmp", "/usr/tmp" ]

    # As a last resort, the current directory.
    try:
        result.add n_os.getcwd()
    except (#[AttributeError, ]# OSError):
        result.add n_os.curdir

proc init_text_openflags: cint{.inline.} =
  result = n_os.O_RDWR or n_os.O_CREAT or n_os.O_EXCL
  when declared(n_os.O_NOFOLLOW):
    result = result or n_os.O_NOFOLLOW

let
  text_openflags = init_text_openflags()
  bin_openflags =
    when compiles(n_os.O_BINARY): text_openflags or n_os.O_BINARY
    else: text_openflags

const DWin = defined(windows)

when DWin:
  const W_OK = 2
  proc c_access(path: cstring, mode: cint): cint{.importc: "_access", header: "<io.h>".}
  proc access(path: string, mode: cint): bool =
    c_access(path.cstring, mode) == 0


proc get_default_tempdir(): string =
    ##[Calculate the default directory to use for temporary files.
    This routine should be called exactly once.

    We determine whether or not a candidate temp dir is usable by
    trying to create and write to a file in that directory.  If this
    is successful, the test file is deleted.  To prevent denial of
    service, the name of the test file must be randomized.]##

    var namer: RandomNameSequence
    namer.initRandomNameSequence()
    var dirlist = candidate_tempdir_list()

    for ori_dir in dirlist:
        let dir = if ori_dir != n_os.curdir:
          n_os.path.abspath(ori_dir)
        else:
          ori_dir
        # Try only a few names per directory.
        for name in namer.items 100:
            let filename = path.join(dir, name)
            try:
                let fd = n_os.open(filename, bin_openflags, 0o600)
                try:
                    #  CPython does followings,
                    #  but I cannot understand why to do so.
                    # try:
                    #     write(fd, b"blat")
                    # finally:
                    #     n_os.close(fd)
                    n_os.close(fd)
                finally:
                    unlink(filename)
                return dir
            except FileExistsError:
                discard
            # except PermissionError:
            except OSError:
                when defined(windows):
                  if n_os.path.isdir(dir) and
                      access(dir, W_OK):
                    # This exception is thrown when a directory with the chosen name
                    # already exists on windows.
                    continue
                break   # no point trying more names in this directory
    raise newException(FileNotFoundError, "No usable temporary directory found in " &
                            $dirlist)


when not defined(js) and not defined(nimscript):
  import std/locks
  var lock: Lock
  lock.initLock()
  template lock_tempdir(body) =
    withLock lock: body
else:
  template lock_tempdir(body) = body

var tempdir*{.threadvar.}: string

proc gettempdir*(): string =
  ## XXX: TODO: gettempdir() should be considered os.fsencode/fsdecode?
  if tempdir.len == 0:
    lock_tempdir:
      tempdir = get_default_tempdir()
  return tempdir

proc gettempprefix*(): string =
  ## Return the default prefix string used by mktemp().
  ## This is 'tmp' on most systems.]
  return templ

type SOption = Option[string]

const sNone = none[string]()

converter sToOpt*(s: string): SOption = 
  some[string](s)

proc sanitize_params(prefix, suffix, dir: SOption): tuple[prefix, suffix, dir: string] =
  
  result.suffix = suffix.get("")
  result.prefix = prefix.get templ
  result.dir = dir.get gettempdir()

type
  TemporaryFileCloser*[IO: IOBase] = ref object
    file*: IO
    name*: string
    delete, close_called: bool
  
  TemporaryFileWrapper*[IO] = object
    closer: TemporaryFileCloser[IO]

template name*(self: TemporaryFileWrapper): string = self.closer.name

import std/macros
macro gen(opName: untyped): untyped =
  let selfId = ident"self"
  quote do:
    template `opName`*[IO](`selfId`: TemporaryFileWrapper[IO],
    args: varargs[typed]): untyped = unpackVarargs `selfId`.closer.file.`opName`, args

gen write
proc flush*[IO](self: TemporaryFileWrapper[IO]) = flush(self.closer.file)
gen read
gen readline
gen seek
gen tell

proc close*[IO](self: TemporaryFileCloser[IO], unlink=os.removeFile) =
    try:
        var f = self.file
        f.close()
    finally:
        if self.delete:
            unlink(self.name)

proc close*(t: TemporaryFileWrapper) =
  t.closer.close()


proc newTemporaryFileCloser[IO](file: IO, name: string, delete=True): TemporaryFileCloser[IO] =
  new result
  result.file = file
  result.name = name
  result.delete = delete
  result.close_called = false


proc newTemporaryFileWrapper[IO](closer: TemporaryFileCloser[IO]): TemporaryFileWrapper[IO] =
  result.closer = closer

template NamedTemporaryFile*(mode: static[string|char] = "w+b", buffering = -1,
    encoding=DefEncoding,
    newline=DefNewLine, suffix=sNone, prefix=sNone,
    dir=sNone, delete=True, errors=DefErrors): TemporaryFileWrapper =
  runnableExamples:
    var tempf = NamedTemporaryFile("w+t")
    let msg = "test"
    tempf.write(msg)
    tempf.flush()
    tempf.seek(0)
    let s = tempf.read()
    assert s == msg

    import std/os
    assert fileExists tempf.name
    tempf.close()
    assert not fileExists tempf.name
  bind TemporaryFileWrapper, newTemporaryFileWrapper, open, sNone, sanitize_params, mktemp
  let
    tup = sanitize_params(prefix, suffix, dir)
    name = mktemp(tup[1], tup[0], tup[2])

  var file = open(name, mode, buffering,
        encoding, errors, newline)
  var closer = newTemporaryFileCloser[typeof(file)](file, name, delete)
  var result = newTemporaryFileWrapper closer
  result


type TemporaryDirectoryWrapper* = object
  name*: string
  ignore_cleanup_errors, delete: bool

proc mkdtemp*(suffix=sNone, prefix=sNone, dir=sNone): string =
  let tup = sanitize_params(prefix=prefix, suffix=suffix, dir=dir)
  mktemp(dir=tup.dir, suffix=tup.suffix, prefix=tup.prefix, checker=dirExists)

proc TemporaryDirectory*(suffix=sNone, prefix=sNone, dir=sNone, ignore_cleanup_errors=False,
     delete=True): TemporaryDirectoryWrapper =
  runnableExamples:
    import std/os
    let d = TemporaryDirectory()
    assert dirExists d.name
    d.cleanup()
    assert not dirExists d.name
  let tup = sanitize_params(suffix=suffix, prefix=prefix, dir=dir)
  result.name = mkdtemp(suffix=tup.suffix, prefix=tup.prefix, dir=tup.dir)
  result.delete = delete
  result.ignore_cleanup_errors = ignore_cleanup_errors
  createDir result.name


proc cleanup*(self: TemporaryDirectoryWrapper) =
  if self.delete:
    try:
      removeDir self.name
    except OSError:
      if not self.ignore_cleanup_errors:
        raise # XXX: see Py's TemporaryDirectory._rmtree for real impl

proc close*(self: TemporaryDirectoryWrapper) =
  ## used to be called in `with` stmt (Python's doesn't have this)
  try: self.cleanup()
  except Exception: discard

when (NimMajor, NimMinor, NimPatch) >= (2, 1, 1):
  ## XXX: FIXED-NIM-BUG: though nimAllowNonVarDestructor is defined at least since 2.0.6,
  ## it still cannot be compiled till abour 2.1.1
  proc `=destroy`*(self: TemporaryDirectoryWrapper) = self.close()
else:
  proc `=destroy`*(self: var TemporaryDirectoryWrapper) = self.close()
