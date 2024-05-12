
import std/os
import std/random
import std/options

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
  for _ in 0..times:
    var letters = newString(8)
    for i in 0 ..< 8:
      let c = self.rng.sample(RandChars)
      letters[i] = c
    yield letters

const templ = "tmp"  # Py's `tempfile.template`

proc mktemp*(suffix="", prefix=templ, dir = "", checker=fileExists): string =
  ## User-callable function to return a unique temporary file/dir name.  The
  ##  file/dir is not created.
  for name in name_sequence.items(times=TMP_MAX):
    let file = dir / prefix & name & suffix
    if not checker file:
      return file
  raise newException(OSError, "No usable temporary filename found")


proc mktemp*(suffix="", prefix=templ): string = 
  mktemp(dir=getTempDir(), suffix=suffix, prefix=prefix)

type SOption = Option[string]

const sNone= none[string]()

converter sToOpt*(s: string): SOption = 
  some[string](s)

proc sanitize_params(prefix, suffix, dir: SOption): tuple[prefix, suffix, dir: string] =
  
  result.suffix = suffix.get("")
  result.prefix = prefix.get templ
  result.dir = dir.get getTempDir()

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
  quote do:
    template `opName`*[IO](self: TemporaryFileWrapper[IO],
    args: varargs[typed]): untyped = unpackVarargs self.closer.file.`opName`, args

gen write
gen flush
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

when NimMajor == 1:
  proc `=destroy`*(self: var TemporaryDirectoryWrapper) = self.close()
else:
  proc `=destroy`*(self: TemporaryDirectoryWrapper) = self.close()
