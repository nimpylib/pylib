
##[

*NOTE*: not support js currently

## different from Python

### open
Its param: `closefd, opener`
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
  import std/[syncio, assertions]

import std/[
  strutils, encodings, os,
  unicode,
  ]
from std/terminal import isatty

import ../io_abc  # PathLike
export io_abc except `$`

import ../pyerrors/oserr
export FileNotFoundError

import ./os_impl/posix_like/truncate
import ./os_impl/posix_like/isatty
import ./ncodec
export DefErrors, LookupError
import ../pystring/[strimpl, strbltins]
import ../pybytes/[bytesimpl, bytesbltins]
import ./warnings

const
  SEEK_SET* = 0
  SEEK_CUR* = 1
  SEEK_END* = 2

const DefNewLine* = "None"  ## here it's used to mean `open(...newline=None)` in Python (i.e. Universial NewLine)

type
  NewlineType = enum
    nlUniversal      ## Universal Newline mode and always use \n
    nlUniversalAsIs  ## Universal Newline mode but returns newline AS-IS
    nlReturn
    nlCarriageReturn
    nlCarriage

type
  IOBase* = ref object of RootObj
    closed*: bool
    file: File # Python does not have this field, but we can use, as here's Nim

type
  UnsupportedOperation* = object of OSError # and ValueError

converter toUnderFile(f: IOBase): File = f.file

proc flush*(f: IOBase) = f.flushFile()

func tell*(f: IOBase): int64 = f.getFilePos()

func isatty*(f: IOBase): bool = f.isatty()

proc fileno*(f: IOBase): int = int getFileHandle f

const DEFAULT_BUFFER_SIZE* = 8192

type
  NoEncTextIOBase* = ref object of IOBase
    ## no encoding conversion is performed on underlying file.
    ## used for those stream whose encoding is alreadly utf-8
    newline: NewlineType
  NoEncTextIOWrapper* = ref object of NoEncTextIOBase
    name*: PyStr
    mode*: PyStr

  TextIOWrapper* = ref object of NoEncTextIOWrapper
    encErrors: EncErrors  ## do not use string, so is always valid
    codec: NCodecInfo
  
func encoding*(s: TextIOWrapper): PyStr = s.codec.name
func errors*(s: TextIOWrapper): PyStr = s.codec.errors

type
  RawIOBase* = ref object of IOBase
  FileIO* = ref object of RawIOBase

  BufferedIOBase* = ref object of IOBase
  BufferedRandom* = ref object of BufferedIOBase
  BufferedReader* = ref object of BufferedIOBase
  BufferedWriter* = ref object of BufferedIOBase

proc parseNewLineType(nl: string): NewLineType =
  case nl
  of DefNewLine: nlUniversal
  of "": nlUniversalAsIs
  of "\n": nlReturn
  of "\r\n": nlCarriageReturn
  of "\r": nlCarriage
  else:  # err like Python
    raise newException(ValueError, "illegal newline value: " & nl)

proc initNewLineMode(self: NoEncTextIOBase, newline: string) =
  self.newline = parseNewLineType newline

template Raise(exc; msg): untyped =
  raise newException(exc, msg)

method seek*(f: IOBase, cookie: int64, whence=SEEK_SET): int64{.base, discardable.} =
  f.setFilePos(cookie, FileSeekPos(whence))
  result = f.getFilePos()
method seek*(self: TextIOWrapper, cookie: int64, whence=SEEK_SET): int64{.discardable.} =
  runnableExamples:
    var f = open("tempfiletest", 'w')
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

proc c_fgetc(stream: File): cint {.
  importc: "fgetc", header: "<stdio.h>", tags: [].}
proc c_ungetc(c: cint, f: File): cint {.
  importc: "ungetc", header: "<stdio.h>", tags: [].}

proc peekChar(self: IOBase): char =
  let ci = c_fgetc(self.file)
  if ci < 0.cint: raise newException(EOFError, "")
  discard c_ungetc(ci, self.file)
  result = char ci

template Iencode =
  result = self.codec.decode(result).data

const NoneChar = '\0'  # means None
type
  NL_t = array[2, char]
  sNL_t = static NL_t
template only1nl(c): untyped = [c, NoneChar]
const AllNL = [NoneChar, NoneChar]

proc add(s: var string, nl: NL_t) =
  if nl[0] == NoneChar: return
  s.add nl[0]
  if nl[1] != NoneChar:
    s.add nl[1]
  
# TODO: re-impl using `_get_decoded_chars` (like Python)
template t_readlineTill(res; cond: bool, till: sNL_t = only1nl('\n')): NL_t = 
  # a very slowish impl...
  var nlRes: NL_t
  try:
    while cond:
      nlRes[0] = self.readChar()
      when till == AllNL:
        if nlRes[0] == '\n':
          nlRes = only1nl '\n'
          break
        elif nlRes[0] == '\r':
          if self.peekChar() == '\n':
            nlRes[1] = self.readChar()
          else:
            nlRes[1] = NoneChar
          break
        else:
          res.add nlRes[0]
      
      else:
        if nlRes[0] == till[0]:
          when till[1] == NoneChar:
            nlRes[1] = NoneChar
            break
          else:
            if self.peekChar() == till[1]:
              nlRes[1] = self.readChar()
              break
            else:
              res.add nlRes[0]
        else:
          res.add nlRes[0]

  except EOFError:
    for e in nlRes.mitems:
      if e notin {'\r', '\n'}:
        e = NoneChar
  nlRes

proc readlineTill(self: IOBase, res: var string, cond: bool, till: sNL_t = only1nl('\n')): NL_t = 
  t_readlineTill res, cond, till

template readlineImpl(self: RawIOBase; cond): untyped{.dirty.} =
  ## The line terminator is always bytes '\n' for binary files
  var res: string
  res.add self.readlineTill(res, cond)
  res
proc readline*(self: RawIOBase): PyBytes = bytes readlineImpl(self, true)
proc readline*(self: RawIOBase, size: Natural): PyBytes =
  bytes readlineImpl(self, res.len<size)

template readlineWithTill(Till) =
  template addTill(nl) = result.add Till(nl)
  case self.newline
  of nlUniversal:
    if Till(AllNL) != [NoneChar, NoneChar]:
      result.add '\n'
  of nlUniversalAsIs: addTill AllNL
  of nlCarriage: addTill only1nl '\r'
  of nlReturn: addTill only1nl '\n'
  of nlCarriageReturn: addTill ['\r', '\n']

proc readlineImpl(self: NoEncTextIOWrapper): string =
  template Till(nl): untyped = self.readlineTill(result, true, nl)
  readlineWithTill Till
  #[case self.newline: of nlUniversal:
    if self.file.readLine(result): if not self.file.endOfFile: result.add '\n']#
  # If coding as above, we have to check EOF, as the line above only returns false when reading at EOF
  # But we just cannot, as Python's `readline()` for `newline=None` even treat '\r' as newline,
  #  while Nim's readline (innerly calling `fgets` of C) doesn't
  
proc readlineImpl(self: NoEncTextIOWrapper, size: int): string =
  template Till(nl): untyped = t_readlineTill(result, result.len<size, nl)
  readlineWithTill Till

proc readline*(self: NoEncTextIOWrapper): PyStr =
  str self.readlineImpl()
proc readline*(self: NoEncTextIOWrapper, size: int): PyStr =
  ## ..warning:: size is currently in bytes, not in characters
  # XXX: see above
  result = str self.readlineImpl(size)

proc readline*(self: TextIOWrapper): PyStr =
  ## Python's readline
  runnableExamples:
    import std/strutils
    const fn = "tempfiletest"
    proc check(ls: varargs[string], newline: string) =
      var f = open(fn, newline=newline)
      for l in ls:
        let s = f.readline()
        assert s == l, 
          "expected $#, but got $#, with newline=$#" % [l.repr, s.repr, newline.repr]
        
      f.close()
    
    writeFile fn, "abc\r\n123\n-\r_"

    check "abc\n", "123\n", "-\n", "_", newline=DefNewLine
    check "abc\r\n", "123\n", "-\r", "_", newline=""
    check "abc\r", "\n123\n-\r", "_", newline="\r"
    check "abc\r\n", "123\n", "-\r_", newline="\n"
    check "abc\r\n", "123\n-\r_", newline="\r\n"
  result = self.readlineImpl()
  Iencode
proc readline*(self: TextIOWrapper, size: Natural): PyStr =
  result = self.readlineImpl(size)
  Iencode

proc read*(self: RawIOBase): PyBytes = bytes self.file.readAll
proc readImpl(self: RawIOBase, size: int): string = 
  discard self.file.readChars(toOpenArray(result, 0, size-1))
proc read*(self: RawIOBase, size: int): PyBytes = bytes self.readImpl(size) 

# TODO: re-impl using `_get_decoded_chars` (like Python)
proc readImpl(self: NoEncTextIOWrapper): string =
  while true:
    let s = self.readlineImpl()
    if s == "": break
    result.add s

proc read*(self: NoEncTextIOWrapper): PyStr = str self.readImpl()
proc read*(self: TextIOWrapper): PyStr =
  result = self.readImpl()
  Iencode

# XXX: very slowish
proc readImpl(self: NoEncTextIOWrapper, size: int): string = 
  var left = size
  while left > 0:
    let s = self.readline(left)
    left.dec s.len
    if s == "": break
    result.add s

proc read*(self: NoEncTextIOWrapper, size: int): PyStr =
  result = self.readImpl(size)

proc read*(self: TextIOWrapper, size: int): PyStr =
  result = self.readImpl(size)
  Iencode

proc write(self: IOBase, s: string): int{.discardable.} =
  self.file.write s
  s.len

proc write*(self: RawIOBase, s: PyBytes): int{.discardable.} =
  write(IOBase(self), $s)

proc writeImpl(self: NoEncTextIOWrapper, s: string, cvtRet: proc(s: string): int): int{.discardable.} =
  proc retSubs(toNewLine: string): int = cvtRet(s.replace("\n", toNewLine))
  case self.newline
  of nlUniversalAsIs, nlReturn:
    # no translation takes place.
    cvtRet s
  of nlUniversal: retSubs "\p"
  of nlCarriage: retSubs "\r"
  of nlCarriageReturn: retSubs "\r\n"

proc write*(self: NoEncTextIOWrapper, s: PyStr): int{.discardable.} =
  proc cvtRet(oriStr: string): int =
    discard write(IOBase(self), s)
    s.len
  writeImpl(self, s, cvtRet)

proc write*(self: TextIOWrapper, s: PyStr): int{.discardable.} =
  ## Writes the `s` to the stream and return the number of characters written
  ## 
  ## The following is from Python's doc of `open`: 
  ## if newline is None, any '\n' characters written are translated to
  ##  the system default line separator, os.linesep.
  ## If newline is "" or '\n', no translation takes place.
  ## If newline is any of the other legal values,
  ## any '\n' characters written are translated to the given string.
  runnableExamples:
    const fn = "tempfiletest"
    proc checkW(s, dest: string, newline=DefNewLine, encoding=DefEncoding;
        writeLen=dest.len  # dest.len returns bytes size
      ) =
      var f = open(fn, 'w', newline=newline, encoding=encoding)
      assert writeLen == f.write s
      f.close()
      let res = readFile fn
      assert dest == res, "expected "&dest.repr&" but got "&res.repr
    checkW "1\n2", when defined(windows): "1\r\n2" else: "1\n2"
    checkW "1\n2", "1\p2"  # same as above
    checkW "1\n2", "1\r2", newline="\r"
    checkW "我", "我", encoding="utf-8", writeLen=1
  
  proc cvtRet(oriStr: string): int =
    let t = self.codec.encode(oriStr)
    discard write(IOBase(self), t.data)
    t.len
  writeImpl(self, s, cvtRet)

proc truncate*(self: IOBase): int{.discardable.} =
  runnableExamples:
    const fn = "tempfiletest"
    var f = open(fn, "w+")
    discard f.write("123")
    f.seek(0)
    f.truncate()
    assert f.read() == ""
    f.close()
  result = self.tell().int
  truncate self.fileno, result

proc truncate*(self: IOBase, size: int64): int64{.discardable.} =
  truncate self.fileno, size
  size

# workaround,
#  a Nim's bug: when ref object+method+var+procCall
#   error: 'self_p0' is a pointer to pointer; did you mean to dereference it before applying '->' to it?
#   close__6958ZprogramZutilsZnimpylibZsrcZpylibZio_u643(&self_p0->Sup);
template base_close() =
  if self.closed: return
  self.closed = true
  self.file.close()
  
method close*(self: IOBase){.base.} = base_close()
method close*(self: RawIOBase) = base_close()
method close*(self: TextIOWrapper) =
  #procCall close IOBase(self)
  base_close()
  self.codec.close()

proc parseErrors(s: string): EncErrors = parseEnum[EncErrors](s, EncErrors.strict)
proc getPreferredEncoding(): string = getCurrentEncoding(true)  ## concrete ANSI when on Windows
const
  DefEncoding* = ""
  LocaleEncoding* = "locale"

template raise_ValueError(s) = raise newException(ValueError, s)

proc toSet(s: string): set[char] =
  for c in s: result.incl c

const False=false
const True=true

template getBlkSize(p: PathLike): int =
  getFileInfo($p, followSymlink=true).blockSize

template getBlkSize(fd: int): int = 0  # TODO: use fstat instead!

proc isatty(p: CanIOOpenT): bool =
  when p is int:
    result = p.isatty()
  else:
    var f: File
    if f.open($p, fmRead):
      result = f.isatty()
      f.close()

proc norm_buffering(file: CanIOOpenT, buffering: var int): bool =
  ## returns line_buffering
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
  result = line_buffering

proc `file=`[I: IOBase](self: var I, file: File) = self.file = file  # EXT.

proc newNoEncTextIO*(file: File, name: string,
    newline=DefNewLine): NoEncTextIOWrapper =
  result = NoEncTextIOWrapper(name: name, file: file)
  result.initNewLineMode(newline)

proc initTextIO(encoding, errors, smode, newline: string): TextIOWrapper =
    var enc = encoding
    if enc == DefEncoding: enc = LocaleEncoding
    if enc == LocaleEncoding: enc = getPreferredEncoding()

    let ncodec = initNCodecInfo(enc, errors)
    result = TextIOWrapper(
      encErrors: parseErrors errors,
      codec: ncodec,
      mode: smode
    )
    result.initNewLineMode(newline)

template genOpenInfo(result: untyped; file; mode: static string, 
  buffering: var int,
  encoding,
  errors,
  newline: string,
  resMode: var FileMode
) =
  ## returns is binary
  bind toSet, raise_ValueError, repr, warn,
    True, False, DeprecationWarning, RuntimeWarning,
    initTextIO,
    TextIOWrapper, 
    RawIOBase, BufferedIOBase, BufferedReader, BufferedWriter, BufferedRandom,
    DefErrors, DefEncoding, norm_buffering,
    FileMode, PathLike, fileExists
  const
    modes = toSet mode
    allSet = toSet("axrwb+tU")
  when len(modes - allSet)!=0 or len(mode) > len(modes):
      raise_ValueError("invalid mode: $#" % mode.repr)
  const
    creating = 'x' in modes
    writing = 'w' in modes
    appending = 'a' in modes
    updating = '+' in modes
    text = 't' in modes
    binary = 'b' in modes
  const
    reading = 
      when 'U' in modes:
          when creating or writing or appending or updating:
              raise_ValueError("mode U cannot be combined with 'x', 'w', 'a', or '+'")
          warn("'U' mode is deprecated",
                        DeprecationWarning, 2)
          True
      else:
          'r' in modes
  when text and binary:
      raise_ValueError("can't have text and binary mode at once")
  when int(creating) + int(reading) + int(writing) + int(appending) > 1:
      raise_ValueError("can't have read/write/append mode at once")
  when not (creating or reading or writing or appending):
      raise_ValueError("must have exactly one of read/write/append mode")
  when binary:
    if (encoding != DefEncoding):
      raise_ValueError("binary mode doesn't take an encoding argument")
  when binary:
    if (errors != DefErrors):
      raise_ValueError("binary mode doesn't take an errors argument")
  #if binary and newline is not None: raise_ValueError("binary mode doesn't take a newline argument")
  when binary:
    if buffering == 1:
      warn("line buffering (buffering=1) isn't supported in binary " &
                    "mode, the default buffer size will be used",
                    RuntimeWarning, 2)
  # raw = FileIO( ... )
  let _ = norm_buffering(file, buffering)  # line_buffering is not used yet
  when not binary:
    if buffering == 0:
        raise_ValueError("can't have unbuffered text I/O")

  when binary:
    var result: RawIOBase
    if buffering == 0:
      result = FileIO()
    else:
      result = FileIO() # XXX: currently it's FileIO but is buffered in fact
      #[
      when updating:
        result = BufferedRandom()
      elif creating or writing or appending:
        result = BufferedWriter()
      elif reading:
        result = BufferedReader()
      else:
        raise_ValueError("unknown mode: $#" % mode.repr)
      ]#
  else:
    var result = initTextIO(encoding, errors, mode, newline)
    # TextIOWrapper( ...line_buffering)

  let nmode =
    when updating: FileMode.fmReadWrite
    elif creating:
      when file is PathLike:
        if fileExists $file:
          raise_FileExistsError("File exists: $#" % file.repr)
      FileMode.fmWrite
    elif reading: FileMode.fmRead
    elif writing: FileMode.fmWrite
    elif appending: FileMode.fmAppend
    else: doAssert false;FileMode.fmRead  # impossible
  resMode = nmode

proc c_setvbuf(f: File, buf: pointer, mode: cint, size: csize_t): cint {.
  importc: "setvbuf", header: "<stdio.h>".}
let
  IOFBF {.importc: "_IOFBF", nodecl.}: cint
  IOLBF {.importc: "_IOLBF", nodecl.}: cint
  # NOTE: For Win32, the behavior is the same as _IOFBF - Full Buffering
  IONBF {.importc: "_IONBF", nodecl.}: cint

# patch for system/io.nim or std/syncio.nim,
# see https://github.com/nim-lang/Nim/pull/23456
const
  NoInheritFlag =
    # Platform specific flag for creating a File without inheritance.
    when not defined(nimInheritHandles):
      when defined(windows): ""
      elif defined(linux) or defined(bsd): "e"
      else: ""
    else: ""
  FormatOpen: array[FileMode, cstring] = [
    cstring("rb" & NoInheritFlag), "wb" & NoInheritFlag, "w+b" & NoInheritFlag,
    "r+b" & NoInheritFlag, "ab" & NoInheritFlag
  ]
when defined(windows):
  proc getOsfhandle(fd: cint): int {.
    importc: "_get_osfhandle", header: "<io.h>".}
  proc c_fdopen(filehandle: cint, mode: cstring): File {.
    importc: "_fdopen", header: "<stdio.h>".}
else:
  proc c_fdopen(filehandle: cint, mode: cstring): File {.
    importc: "fdopen", header: "<stdio.h>".}
proc openNoNonInhertFlag(f: var File, filehandle: FileHandle,
           mode: FileMode = fmRead): bool {.tags: [], raises: [].} =
  when not defined(nimInheritHandles) and declared(setInheritable):
    let oshandle = when defined(windows): FileHandle getOsfhandle(filehandle)
                   else: filehandle
    if not setInheritable(oshandle, false):
      return false
  let fop = FormatOpen[mode]
  f = c_fdopen(filehandle, fop)
  result = f != nil

proc raiseOsOrFileNotFoundError*(file: int) =
    let err = osLastError()
    let fn = "fd: " & $file
    raiseOSError(err,
      "[Errno " & $err & "] " & "can't open " & fn)

proc raiseOsOrFileNotFoundError*[T](file: PathLike[T]) =
  file.raiseExcWithPath()

proc initBufAsPy*(nfile: var File, buf: int) =
  ## init buffering as Python's
  var (bfMode, bfSize) =
    if buf == 1: (IOLBF, 0)
    elif buf > 0 and buf.uint <= high(uint):
      (IOFBF, buf)
    elif buf == 0:
      (IONBF, 0)
    else: doAssert false;(typeof(IOFBF)(0), 0)
  discard c_setvbuf(nfile, nil, bfMode, cast[csize_t](bfSize))

template openImpl(result: untyped;
  file, mode1;
  buffering: int,
  encoding1,
  errors1,
  newline1: typed
  #,closefd=True, opener
) =
  bind genOpenInfo, initTextIO,
    FileMode, FileHandle,
    openNoNonInhertFlag, `file=`
    
  var buf = buffering
  var
    nmode: FileMode
  const smode = $mode1
  genOpenInfo(result, file, smode, buf,
      encoding = encoding1, errors=errors1, newline=newline1, resMode=nmode)
  
  var nfile: File
  when file is int:
    let succ = openNoNonInhertFlag(nfile, FileHandle file, mode=nmode)
  else:
    let succ = open(nfile, $file, mode=nmode)
  # Nim/Python:
  #  The file handle associated with the resulting File is not inheritable.
  if not succ:
    file.raiseOsOrFileNotFoundError()
  nfile.initBufAsPy(buf)
  
  `file=` result, nfile  # cannot write as .file= 

template open*(
  file: int, mode: static[string|char] = "r",
  buffering: int = -1,
  encoding: string = DefEncoding, 
  errors: string = DefErrors,  # in Python, the default None/invalid string means "strict"
  newline: string|char = DefNewLine,
  #closefd=True, opener
): untyped =
  bind openImpl
  block:
    openImpl(res,
      file, mode,
      buffering,
      encoding, 
      errors,
      newline)
    res

template open*[S](
  file: PathLike[S], mode: static[string|char] = "r",
  buffering: int = -1,
  encoding: string = DefEncoding, 
  errors: string = DefErrors,  # in Python, the default None/invalid string means "strict"
  newline: string|char = DefNewLine,
  #closefd=True, opener
): untyped =
  ## WARN:
  ## 
  ## - `line buffering` is not support for Win32
  ## - `errors` is not just ignored, always 'strict'
  
  # TODO: impl line_buffering, at least for write
  runnableExamples:
    const fn = "tempfiletest"
    const nonfn = r"   \:/ $&* "
    doAssertRaises LookupError:
      # raise LookupError instead of FileNotFoundError (like Python)
      discard open(nonfn, encoding="this is a invalid enc")
    doAssertRaises FileNotFoundError:
      discard io.open(nonfn)  # an invalid filename, never existing
    block Write:
      var f = open(fn, "w",  encoding="utf-8")
      let ret = f.write("123\r\n")
      when defined(windows):
        assert ret == 6  # Universal Newline, written "123\r\r\n"
      else:
        assert ret == 5  # written "123\r\n"
      assert not f.closed
      f.close()
      assert f.closed
      assert readFile(fn) == (when defined(windows):"123\r\r\n" else:"123\r\n")
    block Read:
      var f = open(fn, 'r')
      let uniLineRes = f.read() # Universal Newline, "123\r\n\n" -> "123\n\n"
      assert uniLineRes == (when defined(windows):"123\n\n" else:"123\n")
      f.close()
  bind openImpl
  block:
    openImpl(res,
      file, mode,
      buffering,
      encoding, 
      errors,
      newline)
    res

