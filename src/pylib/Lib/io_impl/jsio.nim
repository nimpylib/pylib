# from $nim/lib/std/syncio
{.pragma: benign, gcsafe.}
proc raiseEIO(msg: string) {.noinline, noreturn.} =
  raise newException(IOError, msg)

proc raiseEOF() {.noinline, noreturn.} =
  raise newException(EOFError, "EOF reached")

# ---

import ../../jsutils/denoAttrs

import std/macros
import std/jsffi
when defined(nimPreviewSlimSystem):
  import std/syncio except File
type
  JsNumber = cdouble
  JsIntNumber = distinct int
converter toInt(n: JsIntNumber): int = int(n)

type File*{.pure.} = JsObject
  ## unbuffered byte IO:
  ## 
  ##  - deno: Deno.FileInfo with additional attribute: name
  ##  - node: {fd: <interger>, position: <integer>}

template wrapStdio(ioe) =
  let ioe*{.importDenoOrProcess(ioe).}: File ## ReadStream | WriteStream
  ios.pos = 0.toJs  # unused, however

wrapStdio stdin
wrapStdio stdout
wrapStdio stderr

template denoOr(deno, node): untyped =
  when defined(nodejs): node
  else:
    if inDeno: deno
    else: node

template nodeOr(node, deno): untyped = denoOr(deno, node)

type
  TextEncoder{.importjs.} = object of JsObject
    encoding: cstring
  Uint8Array{.importjs.} = object of JsObject
    length: JsNumber

using buffer: Uint8Array

proc newUint8Array(len: int|Uint8Array = 0): Uint8Array{.importjs: "(new Uint8Array(@))".}
proc subarray(buffer; n: JsNumber): Uint8Array{.importcpp.}
proc len(buffer): int = int buffer.length

proc `[]`(buffer; i: int): uint8 = buffer[i].to uint8
iterator items(buffer): uint8 =
  for i in 0..<buffer.len: yield buffer[i]

proc getChar(buffer, i: int): char = cast[char](buffer[i])
iterator chars(buffer): char =
  for i in 0..<buffer.len: yield buffer.getChar i

proc add(s: var string; buffer; n = buffer.len) =
  for i in 0..<n:
    s.add buffer.getChar i

proc toBytesString(buffer): string =
  when declared(newStringUninit):
    result = newStringUninit(buffer.len)
  result.add buffer

proc `[]=`(buffer; i: int; u: uint8) = buffer[i] = u.toJs
proc toUint8Array(s: string|cstring): Uint8Array =
  result = newUint8Array(s.len)
  for i, c in s:
    result[i] = cast[uint8](c)

using f: File
using fp: cstring

proc isatty*(fd): bool{.importNode(tty, isatty).}

proc isatty*(f): bool =
  nodeOr f.fd.isatty(), f.isTerminal().to bool

proc getFileHandle*(f): FileHandle =
  ## not available on Deno2
  FileHandle (
    nodeOr f.fd do:
      let jsObj = f.rid
      if jsObj.isUndefined:
        raise newException(NotImplementedError, "not available on Deno, since v2")
      jsObj
  ).to JsIntNumber

proc getFilePos*(f): int64
template typeWithAttr(typ; attr; attrType) =
  type typ = JsObject
  proc attr(s: typ): attrType = s.attr.to attrType

const DefBuf = 1024

template writeSyncEnsureAllImpl(f; p: Uint8Array; writeSyncWithbuffer) =
  ## fs.writeSync & FsFile.write[Sync]() does not guarantee that the full buffer will be written in a single call.
  ## ref https://docs.deno.com/api/deno/~/Deno.FsFile.prototype.writeSync;
  ## track https://github.com/denoland/deno/issues/28441
  var written = JsNumber 0
  catchJsErrAndRaise:
    while written < data.length:
      let buffer{.inject.} = newUint8Array(if written == 0: data else: data.subarray(written))
      written += writeSyncWithbuffer

## Deno
proc name(f): string = $(f.name.to cstring)
proc `name=`(f; n: cstring){.importcjs: "(#).name=#".}
proc `name=`(f; n: string) = f.name = cstring n

macro importDeno(def) =
  def.addPragma nnkExprColonExpr.newTree(ident"importjs", newLit "Deno."&def.name&"(@)")

proc openSync(fp): File{.importDeno.}  ## Deno's
type OpenOptions = ref object
  ## https://docs.deno.com/api/deno/~/Deno.OpenOptions
  read = true
  write, append, truncate, createNew: bool
  mode: JsNumber
proc openSync(fp; mode: OpenOptions): File{.importDeno.}

proc createReadStream(fp; options: JsObject): File{.importFs.}
proc createWriteStream(fp; options: JsObject): File{.importFs.}
#stream.Duplex.from
proc close_deno(f){.importjs: "#.close()".}

#proc syncDataSync(f){.importcpp.}
proc truncateSync(f; len: JsNumber){.importcpp.}

proc readSync(f; p: Uint8Array): JsObject #[number|null]#{.importcpp.}
proc writeSync(f; p: Uint8Array): JsIntNumber{.importcpp.}
proc writeSyncEnsureAll(f; p: Uint8Array) =
  writeSyncEnsureAllImpl(f, p):
    f.writeSync(buffer)

type SeekMode{.pure.} = enum
  Current = JsIntNumber 1
  End = 2
  Start = 0

proc seekSync(f;
  offset: JsNumber | int64,
  whence: SeekMode,
): JsIntNumber{.importcpp.}


proc readFileSync(fp): Uint8Array{.importDeno.}

proc readAll_deno(f): string =
  if f.getFilePos() == 0:
    return readFileSync(f.name).toBytesString
  else:
    var buffer = newUint8Array(DefBuf)
    while true:
      let obj = not f.readSync(buffer)
      if obj.isNull:
        break
      result.add(buffer, obj.to int)

typeWithAttr FileInfo, size, JsIntNumber
proc statSync(f): FileInfo{.importcpp.}
proc getFileSize_deno(f): int64 = f.statSync().size.int64

## Node
proc position(f): JsIntNumber = f.position.to JsIntNumber
template importFs(sym, def) = importNode(fs, sym, def)
macro importFs(def) =
  newCall(bindSym"importFs", def.name, def)

type FD = JsIntNumber
using fd: FD
proc fd(f): FD{.importjs: "#.fd".}

proc createReadStream(fp; options: JsObject): File{.importFs.}
proc createWriteStream(fp; options: JsObject): File{.importFs.}
#stream.Duplex.from

proc fs_openSync(fp; flags: cstring|JsIntNumber = "r",
  mode=JsIntNumber 0x666): FD{.importFs(openSync).}

const NodeJsFormatOpen = [
  fmRead: cstring"r",
  fmAppend: "a",
  fmReadWrite: "w+",
  fmReadWriteExisting: "r+",
]

proc closeSync(fd){.importFs.}

#proc datasync(f){.importcpp.}
proc ftruncateSync(fd; len: JsIntNumber){.importFs.}

template read_writeSync(sym){.dirty.} =
  proc sym(fd; buffer: Uint8Array,
    offset: JsIntNumber = 0, length: JsIntNumber = buffer.length - offset,
    position: JsIntNumber = -1  # natural means use such a position with file's pos unchanged
  ): JsIntNumber{.importFs.}

read_writeSync readSync
#proc readSync(fd; buffer[, options]){.importFs.}

proc readChars*(f; a: var openArray[char]): int =
  var buffer = newUint8Array(a.len)

  let n = denoOr readSync(f, buffer) do:
    let n = readSync(f.fd, buffer,
      position=f.position
    )
    f.position += n
  let nn = result + n
  for i in n..<nn:
    a[i] = buffer.getChar i
  result = nn



proc readAll_node(f): string =
  var buffer = newUint8Array(DefBuf)
  while true:
    let n = readSync(f.fd, buffer,
      position=f.position
    )
    result.add buffer, n.int
    f.position += n
    if n < buffer.length:
      break

read_writeSync writeSync

proc writeSyncEnsureAll(fd; p: Uint8Array): JsIntNumber =
  writeSyncEnsureAllImpl(f, p):
    writeSync(fd, buffer)
  JsIntNumber p.length

## buffers: ArrayBufferView[]; ArrayBufferView = TypedArray|DataView
using buffers: var Uint8Array  ## XXX: will be JS Array?
proc writevSync(fd; buffers; position: JsIntNumber): JsIntNumber{.importFs.}
proc writevSync(fd; buffers): JsIntNumber{.importFs.}


type StatOptions = ref object
  bigint: bool
typeWithAttr BigIntStats, size, int64
proc fstatSync(fd; options: StatOptions): JsObject{.importFs.}
proc fstatSyncBigInt(fd): BigIntStats = BigIntStats fstatSync(fd, StatOptions{bigint: true})

proc getFileSize_node(f): int64 = fstatSyncBigInt(f.fd).size

##

proc open*(f: var File, fp; mode: FileMode = fmRead,
    ): bool{.tags: [], raises: [], benign.} =
  catchJsErrAndRaise:
    f = nodeOr(fs_openSync(fp.cstring, NodeJsFormatOpen[mode])):
      var options = newJsObject()  ## OpenOptions
      # https://docs.deno.com/api/deno/~/Deno.OpenOptions
      template add(attr) =
        options.attr = true
      case mode
      of fmRead: add read
      of fmAppend: add append
      of fmWrite: add write
      of fmReadWrite:
        add read
        add write
        add create
        add truncate
      of fmReadWriteExisting:
        add read
        add write
      openSync(fp.cstring, options)

  f.position = toJs JsIntNumber 0
  f.name = fp

proc close*(f){.tags: [], gcsafe, sideEffect.} =
  denoOr close_deno(f), closeSync(f.fd)

proc reopen*(f: var File, fp; mode: FileMode = fmRead): bool {.
  tags: [], benign.} =
  # NIMDIFF: `f: File` -> `f: var File`
  if not f.isNull:
    f.close()
  f = open(fp)


# REUSE ``open*(filename: string,``

# NIMDIFF: `var f: File = nil` -> `var f = default(File)`
#  readFile, writeFile, readLines

# REUSE ``lines*(filename: string): strin``
# REUSE ``lines*(f: File): string``

proc truncate*(f; len=0){.
  tags: [WriteIOEffect], benign.} =
  denoOr(f.truncateSync(len), f.fd.ftruncateSync(len))

proc flushFile*(f){.tags: [WriteIOEffect].} =
  discard  # node/deno's writeSync is non-buffered
#  catchJsErrAndRaise:

proc readAll*(f): string{.
  tags: [ReadIOEffect], benign.} =
  denoOr(f.readAll_deno, f.readAll_node)

proc getFileSize*(f): int64{.tags: [ReadIOEffect], benign.} =
  denoOr(f.getFileSize_deno, f.getFileSize_node)

proc setFilePos*(f; pos: int64, whence: FileSeekPos = fspSet){.benign, sideEffect.} =
  denoOr f.seekSync(pos, SeekMode(whence)):
    f.position = case whence
    of fspSet: pos
    of fspCur: pos + f.position
    of fspEnd: f.getFileSize + pos


proc getFilePos*(f): int64{.benign.} =
  nodeOr f.position.to(JsNumber).int64:
    f.seekSync(0, SeekMode.Current)

template readOrWriteCharImpl(readOrWrite): JsIntNumber =
  var buffer = newUint8Array(1)
  nodeOr readOrWrite(f.fd, buffer) do:
    let obj = f.readOrWrite(buffer)
    if obj.isNull: 0 else: obj.to JsIntNumber

proc readChar*(f): char{.
  tags: [ReadIOEffect], benign.} =
  case readOrWriteCharImpl readSync
  of 0: raiseEOF()
  of 1: return buffer[0].char
  else: raiseIO("readChar")  ## FIXME: better msg

proc readChars*(f; a: var openArray[char]): int{.
  tags: [ReadIOEffect], benign.} =
  var buffer = newUint8Array(a.len)

  let n = denoOr readSync(f, buffer) do:
    f.position += n
    readSync(f.fd, buffer,
      position=f.position
    )
  let nn = result + n
  for i in n..<nn:
    a[i] = buffer.getChar i
  result = nn

proc peekChar*(f): char =
  ## NONIM
  nodeOr:
    var buffer = newUint8Array(1)
    if readSync(f.fd, buffer, position = -1) != 1:
      raiseEIO()
    result = buffer.getChar 1
  do:
    result = f.readChar()
    f.seek(-1)

#proc readLine*(f: File, line: var string): bool {.tags: [ReadIOEffect], benign.} =

proc writeRetI*(f; s: string): int{.tags: [WriteIOEffect], benign.} =
  ## NONIM
  let buffer = s.toUint8Array
  result = denoOr f.writeSync(buffer).int do:
    let n = writeSync(f.fd, buffer, position=f.position)
    f.position += n
    n

proc write*(f; s: string|cstring){.tags: [WriteIOEffect], benign.} =
  let buffer = s.toUint8Array
  result = denoOr f.writeSyncEnsureAll(buffer) do:
    f.position += writeSyncEnsureAll(f.fd, buffer, position=f.position)

proc toString(o: JsObject): cstring{.importcpp.}

template genWriteImpl(arg, T, resWithArg){.dirty.} =
  proc write*(f; arg: T) {.tags: [WriteIOEffect], benign.} =
    f.write resWithArg

template genWriteJ(arg, T) =
  ## using JS toString
  genWriteImpl arg, T, arg.toJs.toString

template genWriteN(arg, T) =
  ## using Nim `$`
  genWriteImpl arg, T, $arg

genWriteJ i, int
genWriteJ i, BiggestInt
# REUSE: ``write*(f: File, b: bool)``
genWriteN r, float32|BiggestFloat

proc writeChar*(f; c: char){.
  tags: [WriteIOEffect], benign.} =
  if 1 == readOrWriteCharImpl writeSync:
    return
  else: raiseIO("writeChar")  ## FIXME: better msg

# REUSE: ``write*(f: File, a: varargs[string, `$`])``

proc endOfFile*(f: File): bool {.tags: [], benign.} =
  0 == readOrWriteCharImpl readSync

# REUSE ``writeLine*[Ty](f: File, x: varargs[Ty, `$`])``

{.pragma: notImpl, error: "not impl for JS".}
when defined(js):
  proc setStdIoUnbuffered*() {.tags: [], benign, notImpl.}

  proc readLine*(f: File, line: var string): bool {.tags: [ReadIOEffect],
              benign, notImpl.}
