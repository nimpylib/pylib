
import std/terminal

# Nim consider it's the same as os.terminal_size,
# as they are both tuple of Nim
type terminal_size = tuple[columns, lines: int]
proc get_terminal_size*(fallback=(80, 24)): terminal_size =
  ## .. hint:: this does not simply refer to environment variable,
  ## call `os.get_terminal_size`. This is a wrapper around
  ## `terminalSize` of `std/terminal`, which is more steady,
  ## returning meaningful result even when stdout is not associatd with
  ## a terminal.
  result.columns = terminalWidth()
  if result.columns == 0:
    result.columns = fallback[0]
  result.lines = terminalHeight()
  if result.lines == 0:
    result.lines = fallback[1]

import std/os
when defined(posix):
  import std/posix
import ../pyerrors/oserr
import ../io_abc

const COPY_BUFSIZE = when defined(windows): 64 * 1024 else: 16 * 1024
# Python uses as followings, but it seems too large
# when defined(windows): 1024 * 1024 else: 64 * 1024

proc copyfileobjImpl(s, d: File, length=COPY_BUFSIZE) =
  ## shutil.copyfileobj but for Nim's `File`, here length must be positive
  let bufferSize = length
  # The following is modified from Nim-2.1.1/Lib/std/private/osfiles.nim L241
  # generic version of copyFile which works for any platform:

  # Hints for kernel-level aggressive sequential low-fragmentation read-aheads:
  # https://pubs.opengroup.org/onlinepubs/9699919799/functions/posix_fadvise.html
  when defined(linux) or defined(osx):
    discard posix_fadvise(getFileHandle(d), 0.cint, 0.cint, POSIX_FADV_SEQUENTIAL)
    discard posix_fadvise(getFileHandle(s), 0.cint, 0.cint, POSIX_FADV_SEQUENTIAL)
  var buf = alloc(bufferSize)
  while true:
    var bytesread = readBuffer(s, buf, bufferSize)
    if bytesread > 0:
      var byteswritten = writeBuffer(d, buf, bytesread)
      if bytesread != byteswritten:
        dealloc(buf)
        raiseOSError(osLastError())
    if bytesread != bufferSize: break
  dealloc(buf)
  flushFile(d)

proc copyfileobj*(s, d: File, length=COPY_BUFSIZE) =
  ## shutil.copyfileobj but for Nim's `File`
  ## 
  ## if `length` is negative, it means copying the data
  ## without looping over the source data in chunks
  if length < 0:
    d.write(s.readAll())
    return
  copyfileobjImpl(s, d, length)

type
  Error = object of OSError  ## python's shutil.Error
  SameFileError* = object of Error
template copyFileImpl(src, dst: string; options: CopyFlag) =
  ## called by copyfile
  bind copyFile, copyfileobjImpl
  when defined(windows):
    # std/os's `copyFile` under Windows calls copyFileW,
    # which will copy file attributes too.
    # so we use another implementation instead.
    let isSymlink = src.symlinkExists
    if isSymlink and cfSymlinkAsIs in options:
      createSymlink(expandSymlink(source), dest)
      return
    var
      fsrc = open(src)
      fdst = open(dst, fmWrite)
    defer:
      fsrc.close()
      fdst.close()
    copyfileobjImpl(fsrc, dst)
  else:
    copyFile(src, dst, options)

template copyGen(pyname, impl) =
  proc pyname*[T](src, dst: PathLike[T], follow_symlinks=true) =
    let
      ssrc = $src
      sdst = $dst
      pth = pathsAsOne(src, dst)
      cpOptions = if follow_symlinks: {cfSymlinkFollow} else: {cfSymlinkAsIs}
    if sameFile(ssrc, sdst):
      raise newException(SameFileError, pth)
    pth.tryOsOp: impl(ssrc, sdst, options=cpOptions)

copyGen copyfile, copyFileImpl

proc copyWithPermissions(src, dst: string,
    options={cfSymlinkFollow}) =
  let dstFile = if dst.dirExists: dst / src.lastPathPart
                else: dst
  copyFileWithPermissions(src, dstFile,
      false,  # we do not `ignorePermissionErrors`
      options)

copyGen copy, copyWithPermissions
