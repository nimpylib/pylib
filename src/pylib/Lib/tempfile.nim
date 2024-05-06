
import std/os
import std/random
import std/options

when defined(js): {.error: "pylib tempfile not support JS currently".}
import ../io
export io

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

proc mktemp*(dir: string, suffix="", prefix=templ, checker=fileExists): string =
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
  TemporaryFileCloser* = object
    file*: IOBase
    name*: string
    delete, close_called: bool
  
  TemporaryFileWrapper* = object
    closer: TemporaryFileCloser

template name*(self: TemporaryFileWrapper): string = self.closer.name

import std/macros
macro gen(opName: untyped): untyped =
  quote do:
    template `opName`*(self: TemporaryFileWrapper,
    args: varargs[typed]): untyped = unpackVarargs self.closer.file.`opName`, args

gen write
gen flush
gen read
gen readline
gen seek
gen tell

proc close*(self: TemporaryFileCloser, unlink=os.removeFile) =
    try:
        var f = self.file
        f.close()
    finally:
        if self.delete:
            unlink(self.name)

proc close*(t: TemporaryFileWrapper) =
  t.closer.close()


proc newTemporaryFileCloser(file: IOBase, name: string, delete=True): TemporaryFileCloser =
  result.file = file
  result.name = name
  result.delete = delete
  result.close_called = false



template destoryImpl =
  try: self.close()
  except Exception: discard
when NimMajor == 1:
  proc `=destroy`*(self: var TemporaryFileCloser) = destoryImpl
else:
  proc `=destroy`*(self: TemporaryFileCloser) = destoryImpl

proc NamedTemporaryFile*(mode="w+b", buffering = -1, encoding=DefEncoding,
                       newline=DefNewLine, suffix=sNone, prefix=sNone,
                       dir=sNone, delete=True, errors=DefErrors): TemporaryFileWrapper =
  runnableExamples:
    var tempf = NamedTemporaryFile()
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

  let
    tup = sanitize_params(prefix, suffix, dir)
    name = mktemp(suffix=tup.suffix, prefix=tup.prefix, dir=tup.dir)

  var file = io.open(name, mode, buffering=buffering,
                        newline=newline, encoding=encoding, errors=errors)
  var closer = newTemporaryFileCloser(file, name, delete)
  result.closer = closer


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
