##[

## different from Python

### open
Its param: `newline, closefd, opener`
is not implemented yet

### seek
There is difference that Python's `TextIOBase.seek`
will reset state of encoder at some conditions,
while Nim doesn't have access to encoder's state
Therefore, `seek` here doesn't change that

### iter over file
Python's `__next__` will yield newline as part of result
but Nim's `iterator lines` does not

]##

when defined(nimPreviewSlimSystem):
  import std/syncio

import std/[
  strutils, encodings, os
  ]
from std/terminal import isatty

const
  SEEK_SET* = 0
  SEEK_CUR* = 1
  SEEK_END* = 2

type
  IOBase* = object of RootObj
    closed*: bool
    file: File # Python does not have this field, but we can use, as here's Nim

type
  LookupError* = object of CatchableError
  FileExistsError* = object of OSError
  UnsupportedOperation* = object of OSError # and ValueError


converter toUnderFile(f: IOBase): File = f.file

proc flush*(f: IOBase) = f.flushFile()

func tell*(f: IOBase): int64 = f.getFilePos()

func isatty*(f: IOBase): bool = f.isatty()

proc fileno*(f: IOBase): int = int getFileHandle f  # or getOsFileHandle ?
const DEFAULT_BUFFER_SIZE = 8192

# XXX: not take effect yet
type EncErrors*{.pure.} = enum
  strict  ## - raise a ValueError error (or a subclass)
  ignore  ## - ignore the character and continue with the next
  replace ##[  - replace with a suitable replacement character;
             Python will use the official U+FFFD REPLACEMENT
             CHARACTER for the builtin Unicode codecs on
             decoding and "?" on encoding.]##
  surrogateescape   ## - replace with private code points U+DCnn.
  xmlcharrefreplace ## - Replace with the appropriate XML
                      ##   character reference (only for encoding).
  backslashreplace  ## - Replace with backslashed escape sequences.
  namereplace       ## - Replace with \N{...} escape sequences
                      ##   (only for encoding).

type
  TextIOBase* = object of IOBase
    encoding*: string
    errors*: string 
    encErrors: EncErrors  ## do not use string, so is always valid
    iEncCvt, oEncCvt: EncodingConverter

  TextIOWrapper* = object of TextIOBase
    name*: string
    mode*: string
  
  RawIOBase* = object of IOBase
  FileIO* = object of RawIOBase

  BufferedIOBase* = object of IOBase
  BufferedRandom* = object of BufferedIOBase
  BufferedReader* = object of BufferedIOBase
  BufferedWriter* = object of BufferedIOBase

template Raise(exc; msg): untyped =
  raise newException(exc, msg)

method seek*(f: IOBase, cookie: int64, whence=SEEK_SET): int64{.base, discardable.} =
  f.setFilePos(cookie, FileSeekPos(whence))
  result = f.getFilePos()
method seek*(self: TextIOBase, cookie: int64, whence=SEEK_SET): int64{.discardable.} =
  runnableExamples:
    var f = open("tempfiletest",'w')
    doAssertRaises UnsupportedOperation:
      f.seek(1, SEEK_CUR)
    f.close()
  if self.closed:
    Raise ValueError, ("tell on closed file")
  var
    mwhence = whence
    mcookie = cookie
  case whence
  of SEEK_CUR:
    if cookie != 0:
      Raise UnsupportedOperation, ("can't do nonzero end-relative seeks")
    # Seeking to the current position should attempt to
    # sync the underlying buffer with the current position.
    mwhence = 0
    mcookie = self.tell()
  of SEEK_END:
    if cookie != 0:
      Raise UnsupportedOperation, ("can't do nonzero end-relative seeks")
    self.flush()
    return procCall seek(IOBase(self), 0, whence)
  else: discard
  if whence != SEEK_SET:
    Raise ValueError, ("unsupported whence ($#)" % $whence)
  # whence == SEEK_SET
  if cookie < 0:
    Raise ValueError, ("negative seek position '$#'" % $cookie)
  self.flush()

  # XXX: Python has accessment to its encoder state,
  # but not Nim, thus here is no state reset or relative behavior...
  # the following is Python's doc comment:

  # The strategy of seek() is to go back to the safe start point
  # and replay the effect of read(chars_to_skip) from there.
  return procCall seek(IOBase(self), 0, whence)

template Iencode = 
  result = self.iEncCvt.convert result
method read*(self: IOBase): string{.base.} = self.file.readAll
method read*(self: IOBase, size: int): string{.base.} = 
  discard self.file.readChars(toOpenArray(result, 0, size-1))

method read*(self: TextIOBase): string =
  result = procCall read IOBase(self)
  Iencode
method read*(self: TextIOBase, size: int): string = 
  result = procCall read(IOBase(self), size)
  Iencode

method readline*(self: IOBase): string{.base.} = 
  self.file.readLine()
method readline*(self: TextIOBase): string =
  result = procCall readline IOBase(self)
  Iencode
  
  
method write*(self: IOBase, s: string): int{.base.} =
  self.file.write s
  s.len
method write*(self: TextIOBase, s: string): int =
  result = procCall write(IOBase(self), self.oEncCvt.convert(s))

method close*(self: var IOBase){.base.} =
  if self.closed: return
  self.closed = false
  self.file.close()
method close*(self: var TextIOBase) =
  procCall close IOBase(self)
  self.iEncCvt.close()
  self.oEncCvt.close()

proc parseErrors(s: string): EncErrors = parseEnum[EncErrors](s, EncErrors.strict)
proc getPreferredEncoding(): string = getCurrentEncoding(true)  ## concrete ANSI when on Windows
const
  DefEncoding* = ""
  DefErrors* = "strict"
  LocaleEncoding* = "locale"

type WarnTyp = enum
  DeprecationWarning, RuntimeWarning
# XXX: `warnings.warn` shall be more than just the folowing:
let warnings = (warn: proc (s: string, typ: WarnTyp, lvl: int)=echo $typ & s)

template raise_ValueError(s) = raise newException(ValueError, s)
template raise_FileExistsError(s) = raise newException(FileExistsError, s)

proc toSet(s: string): set[char] =
  for c in s: result.incl c

const False=false
const True=true

template getBlkSize(p: string): int =
  getFileInfo(p, followSymlink=true).blockSize

proc isatty(p: string): bool =
  var f: File
  if f.open(p, fmRead):
    result = f.isatty()
    f.close()

template genOpenInfo(result; file: string, mode: string, 
  buffering: var int,
  encoding,
  errors: string,
  isBinary: var bool, resMode: var FileMode
) = 
  let
    modes = mode.toSet
    allSet = toSet("axrwb+tU")
  if len(modes - allSet)!=0 or len(mode) > len(modes):
      raise_ValueError("invalid mode: '$#'" % mode)

  let
    creating = 'x' in modes
    writing = 'w' in modes
    appending = 'a' in modes
    updating = '+' in modes
    text = 't' in modes
    binary = 'b' in modes
  var
    reading = 'r' in modes
  if 'U' in modes:
      if creating or writing or appending or updating:
          raise_ValueError("mode U cannot be combined with 'x', 'w', 'a', or '+'")
      warnings.warn("'U' mode is deprecated",
                    DeprecationWarning, 2)
      reading = True
  if text and binary:
      raise_ValueError("can't have text and binary mode at once")
  if int(creating) + int(reading) + int(writing) + int(appending) > 1:
      raise_ValueError("can't have read/write/append mode at once")
  if not (creating or reading or writing or appending):
      raise_ValueError("must have exactly one of read/write/append mode")
  if binary and (encoding != DefEncoding):
      raise_ValueError("binary mode doesn't take an encoding argument")
  if binary and (errors != DefErrors):
      raise_ValueError("binary mode doesn't take an errors argument")
  #if binary and newline is not None: raise_ValueError("binary mode doesn't take a newline argument")
  if binary and buffering == 1:
      warnings.warn("line buffering (buffering=1) isn't supported in binary " &
                    "mode, the default buffer size will be used",
                    RuntimeWarning, 2)
  # raw = FileIO( ... )
  var line_buffering = False  # not used yet here
  if buffering == 1 or buffering < 0 and file.isatty():
      buffering = -1
      line_buffering = True
  if buffering < 0:
      buffering = DEFAULT_BUFFER_SIZE
      try:
          #bs = os.fstat(raw.fileno()).st_blksize
          let bs = getBlkSize file
          if bs > 1: buffering = bs
      except OSError: discard
  if buffering < 0: raise_ValueError("invalid buffering size")
  if buffering == 0:
      if not binary:
        raise_ValueError("can't have unbuffered text I/O")
      result = FileIO()
  else: 
    if binary:
      if updating:
        result = BufferedRandom()
      elif creating or writing or appending:
        result = BufferedWriter()
      elif reading:
        result = BufferedReader()
      else:
        raise_ValueError("unknown mode: '$#'" % mode)
    else:
      discard # will be TextIOWrapper( ...line_buffering)

  template chk(m: char): bool = m in modes
  let nmode =
    if chk 'w': FileMode.fmWrite
    elif chk 'a': FileMode.fmAppend
    elif chk 'x':
      if fileExists file:
        raise_FileExistsError("File exists: '$#'" % file)
      FileMode.fmWrite
    elif chk '+': FileMode.fmReadWrite
    else:   FileMode.fmRead
  
  isBinary = binary
  resMode = nmode

proc open*(
  file: string, mode: string|char = "r",
  buffering: int = -1,
  encoding: string = DefEncoding, 
  errors: string = DefErrors,  # in Python, the default None/invalid string means "strict"
  #newline
  #closefd=True, opener
): IOBase = 
  runnableExamples:
    const fn = "tempfiletest"
    doAssertRaises LookupError:
      discard open(fn, encoding="this is a invalid enc")
    let f = open(fn, "w",  encoding="utf-8")
    assert f.write("123") == 3
  var buf = buffering
  var
    nmode: FileMode
    binary = false
  let smode = $mode
  genOpenInfo(result, file, mode = smode, buffering=buf,
      encoding=encoding, errors=errors, isBinary=binary,resMode=nmode)
  
  var file = system.open(file, mode=nmode, bufSize=buf)
  
  if not binary:
    var iEncCvt, oEncCvt: EncodingConverter

    var enc = encoding
    if enc == DefEncoding: enc = LocaleEncoding
    if enc == LocaleEncoding: enc = getPreferredEncoding()

    try:
      iEncCvt = encodings.open(
        destEncoding = "UTF-8",
        srcEncoding = enc
      )
      oEncCvt = encodings.open(
        destEncoding = enc,
        srcEncoding = "UTF-8"
      )
    except ValueError:
      raise newException(LookupError, "unknown encoding: " & encoding)
  
    result = TextIOWrapper(
        file: file,
        errors: errors,
        encErrors: parseErrors errors,
        iEncCvt: iEncCvt,
        oEncCvt: oEncCvt,
        encoding: encoding,
        mode: smode,
    )
  else:
    result.file = file


when isMainModule:
  var f = io.open("f.txt")
  discard f.write("qwe")
  f.close()
  