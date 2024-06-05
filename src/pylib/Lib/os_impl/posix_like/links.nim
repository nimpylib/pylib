

import std/os
import ../common
when defined(windows):
  import std/winlean
  type
    LPVOID = pointer
    LPDWORD = ptr DWORD
    LPOVERLAPPED = pointer  # we don't use it
  let FSCTL_GET_REPARSE_POINT{.importc, header: "<winioctl.h>".}: DWORD
  proc deviceIoControl(hDevice: HANDLE; dwIoControlCode: DWORD;
                      lpInBuffer: LPVOID; nInBufferSize: DWORD;
                      lpOutBuffer: LPVOID; nOutBufferSize: DWORD;
                      lpBytesReturned: LPDWORD; lpOverlapped: LPOVERLAPPED): WINBOOL{.
                      importc: "DeviceIoControl", header: "<ioapiset.h>".}
  
  type
    USHORT = uint16
    WCHAR = winlean.WinChar
    UCHAR = uint8

    ULONG = uint32
    # XXX: winlean.ULONG is defined as int32

  ##  The following structure was translated7474 from
  ##    http://msdn.microsoft.com/en-us/library/ff552012.aspx as the required
  ##    include km\ntifs.h isn't present in the Windows SDK (at least as included
  ##    with Visual Studio Express). Use unique names to avoid conflicting with
  ##    the structure as defined by Min GW.

  type
    INNER_C_STRUCT_Py_REPARSE_DATA_BUFFER_6 {.bycopy.} = object
      SubstituteNameOffset: USHORT
      SubstituteNameLength: USHORT
      PrintNameOffset: USHORT
      PrintNameLength: USHORT
      Flags: ULONG
      PathBuffer: UncheckedArray[WCHAR]

    INNER_C_STRUCT_Py_REPARSE_DATA_BUFFER_7 {.bycopy.} = object
      SubstituteNameOffset: USHORT
      SubstituteNameLength: USHORT
      PrintNameOffset: USHORT
      PrintNameLength: USHORT
      PathBuffer: UncheckedArray[WCHAR]

    INNER_C_STRUCT_Py_REPARSE_DATA_BUFFER_8 {.bycopy.} = object
      DataBuffer: UncheckedArray[UCHAR]

    INNER_C_UNION_Py_REPARSE_DATA_BUFFER_5 {.bycopy, union.} = object
      SymbolicLinkReparseBuffer: INNER_C_STRUCT_Py_REPARSE_DATA_BUFFER_6
      MountPointReparseBuffer: INNER_C_STRUCT_Py_REPARSE_DATA_BUFFER_7
      GenericReparseBuffer: INNER_C_STRUCT_Py_REPARSE_DATA_BUFFER_8

    Py_REPARSE_DATA_BUFFER {.bycopy.} = object
      ReparseTag: ULONG
      ReparseDataLength: USHORT
      Reserved: USHORT
      inner_c_union: INNER_C_UNION_Py_REPARSE_DATA_BUFFER_5

    Py_PREPARSE_DATA_BUFFER = ptr Py_REPARSE_DATA_BUFFER

    Py_ssize_t = int  # XXX: not the same, just minic
    wchar_t = WCHAR
    Wstr = ptr wchar_t
  func `==`(a, b: wchar_t): bool = int16(a) == int16(b)
  template atN(p: Wstr, i: int): Wstr =
    cast[Wstr](
      cast[Py_ssize_t](p) + Py_ssize_t(i * sizeof(wchar_t))
    )
  proc `[]`(p: Wstr, i: int): wchar_t = p.atN(i)[]
  proc `[]=`(p: Wstr, i: int, x: wchar_t) =
    let np = p.atN i
    np[] = x
  proc startsWith(s: Wstr, sub: cstring, n: int): bool =
    # assert s's length is no less than n
    # assert sub is all ASCII.
    result = true
    for i in 0..<n:
      if s[i] != wchar_t(sub[i]):
        return false

  const
    halfShift = 10
    halfBase = 0x0010000
    halfMask = 0x3F

    UNI_SUR_HIGH_START = 0xD800
    UNI_SUR_HIGH_END = 0xDBFF
    UNI_SUR_LOW_START = 0xDC00
    UNI_SUR_LOW_END = 0xDFFF
    #UNI_REPL = 0xFFFD
  template ones(n: untyped): untyped = ((1 shl n)-1)
  # copyed from std/widestrs but change param `w`'s type from WideCString to Wstr
  proc `$`(w: Wstr, estimate: int, replacement: int = 0xFFFD): string =
    result = newStringOfCap(estimate + estimate shr 2)

    var i = 0
    while w[i].int16 != 0'i16:
      var ch = ord(w[i])
      inc i
      if ch >= UNI_SUR_HIGH_START and ch <= UNI_SUR_HIGH_END:
        # If the 16 bits following the high surrogate are in the source buffer...
        let ch2 = ord(w[i])

        # If it's a low surrogate, convert to UTF32:
        if ch2 >= UNI_SUR_LOW_START and ch2 <= UNI_SUR_LOW_END:
          ch = (((ch and halfMask) shl halfShift) + (ch2 and halfMask)) + halfBase
          inc i
        else:
          #invalid UTF-16
          ch = replacement
      elif ch >= UNI_SUR_LOW_START and ch <= UNI_SUR_LOW_END:
        #invalid UTF-16
        ch = replacement

      if ch < 0x80:
        result.add chr(ch)
      elif ch < 0x800:
        result.add chr((ch shr 6) or 0xc0)
        result.add chr((ch and 0x3f) or 0x80)
      elif ch < 0x10000:
        result.add chr((ch shr 12) or 0xe0)
        result.add chr(((ch shr 6) and 0x3f) or 0x80)
        result.add chr((ch and 0x3f) or 0x80)
      elif ch <= 0x10FFFF:
        result.add chr((ch shr 18) or 0xf0)
        result.add chr(((ch shr 12) and 0x3f) or 0x80)
        result.add chr(((ch shr 6) and 0x3f) or 0x80)
        result.add chr((ch and 0x3f) or 0x80)
      else:
        # replacement char(in case user give very large number):
        result.add chr(0xFFFD shr 12 or 0b1110_0000)
        result.add chr(0xFFFD shr 6 and ones(6) or 0b10_0000_00)
        result.add chr(0xFFFD and ones(6) or 0b10_0000_00)

  const
    IO_REPARSE_TAG_SYMLINK = ULONG 0xA000000C
    IO_REPARSE_TAG_MOUNT_POINT = ULONG 0xA0000003
  # _Py_MAXIMUM_REPARSE_DATA_BUFFER_SIZE  ( 16 * 1024 )

  const REPARSE_BUFSIZE = 16 * 1024
  proc readlinkWinImpl(path: string): string =
    ## returns utf-8 encoded path
    # ref posixmodule.c L10129

    let wstr = newWideCString path
    var
      n_bytes_returned: DWORD
      io_result: WINBOOL
      target_buffer: pointer
    when compileOption("threads"):
      target_buffer = allocShared(REPARSE_BUFSIZE)
      defer: target_buffer.deallocShared()
    else:
      target_buffer = alloc(REPARSE_BUFSIZE)
      defer: target_buffer.dealloc()
    # In CPython's impl, target_buffer is on the stack...
    # So no need to deallocate manually.
    # But if we do so in Nim, we have to use a lot `addr` as
    # in C, array converts to pointer implicitly, but not in Nim.

    var rdb = cast[Py_PREPARSE_DATA_BUFFER](target_buffer)
    let reparse_point_handle = createFileW( wstr,
          0, 0, nil,
          OPEN_EXISTING,
          FILE_FLAG_OPEN_REPARSE_POINT or FILE_FLAG_BACKUP_SEMANTICS,
          0)
    if (reparse_point_handle != INVALID_HANDLE_VALUE):
      io_result = deviceIoControl(reparse_point_handle,
              FSCTL_GET_REPARSE_POINT,
              nil, 0, # in buffer
              target_buffer, REPARSE_BUFSIZE,
              addr n_bytes_returned,
              nil # we're not using OVERLAPPED_IO
      )
      discard closeHandle(reparse_point_handle)
    if io_result == WINBOOL(0):
      raiseOSError(osLastError())

    var
      name: ptr wchar_t = nil
      nameLen: Py_ssize_t = 0
    template add_char_ptr(a, b): ptr wchar_t =
      cast[ptr wchar_t](
        cast[int](a) + cast[int](b)
      )

    template rdbAs(union): untyped = rdb.inner_c_union.union
    template calLen(nameLength: USHORT): untyped =
      Py_ssize_t(nameLength) div Py_ssize_t sizeof((wchar_t))
    template extractName(rbuf) =
      name = add_char_ptr(rbuf.PathBuffer,
                          rbuf.SubstituteNameOffset)
      nameLen = calLen rbuf.SubstituteNameLength
    case rdb.ReparseTag
    of IO_REPARSE_TAG_SYMLINK:
      template rbuf: untyped = rdbAs SymbolicLinkReparseBuffer
      rbuf.extractName()
    of IO_REPARSE_TAG_MOUNT_POINT:
      template rbuf: untyped = rdbAs MountPointReparseBuffer
      rbuf.extractName()
    else:
      raise newException(ValueError, "not a symbolic link")
    if name != nil:
      if nameLen > 4 and name.startsWith(cstring"\\??\\", 4):
        ##  Our buffer is mutable, so this is okay
        name[1] = wchar_t('\\')
      result = $(name, nameLen)
    return result


proc readlinkImpl(path: string): string =
  when defined(windows):
    result = readlinkWinImpl path
  else:
    result = expandSymlink(path)


proc readlink*[T](path: PathLike[T]): T =
  try: result = mapPathLike[T] readlinkImpl $path
  except OSError as e:
    let errCode = e.errorCode.OSErrorCode
    if errCode.isNotFound:
      path.raiseFileNotFoundError()
    # XXX: may be other errors?
    raise

when defined(windows):
  proc check_dir(src_resolved: string): bool =
    # do not use dirExists(), as it follows symlink
    # but GetFileAttributesW doesn't
    let src_resolvedW = newWideCString src_resolved

    let res = getFileAttributesW(src_resolvedW)
    result = res == FILE_ATTRIBUTE_DIRECTORY

  var windows_has_symlink_unprivileged_flag = true
  # Assumed true, set to false if detected to not be available.
  proc os_symlink_impl(src, dst: string, target_is_directory: bool = false): bool =
    ## returns if error ocurrs
    const
      SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE = 2
      ERROR_INVALID_PARAMETER = 87
    var flags: int32 = 0
    if windows_has_symlink_unprivileged_flag:
      flags = flags or SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
    
    let
      dest_parent = parentDir dst
      src_resolved = joinPath(dest_parent, src)
    var wSrc = newWideCString(src)
    var wDst = newWideCString(dst)
    if target_is_directory or check_dir(src_resolved):
      flags = flags or SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
    
    # allows anyone with developer mode on to create a link
    var ret = createSymbolicLinkW(wDst, wSrc, flags)
    if windows_has_symlink_unprivileged_flag and ret == 0 and
        getLastError() == ERROR_INVALID_PARAMETER:
      #[This error might be caused by
        SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE not being supported.
        Try again, and update windows_has_symlink_unprivileged_flag if we
        are successful this time.

        NOTE: There is a risk of a race condition here if there are other
        conditions than the flag causing ERROR_INVALID_PARAMETER, and
        another process (or thread) changes that condition in between our
        calls to CreateSymbolicLink.]#
      flags = flags and not SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
      ret = createSymbolicLinkW(wDst, wSrc, flags)

      if ret != 0 or ERROR_INVALID_PARAMETER != getLastError():
        windows_has_symlink_unprivileged_flag = false
    
    if ret == 0:
      result = true
      #raiseOSError(osLastError(), $(src, dest))
else:
  proc c_symlink(target, linkpath: cstring): cint{.importc: "symlink", header: "<unistd.h>".}
  proc c_symlinkat(target, newdirfd: cint, linkpath: cstring): cint{.importc: "symlinkat", header: "<unistd.h>".}
  proc os_symlink_impl(src, dst: string, target_is_directory{.used.}: bool = false): bool =
    if c_symlink(src.cstring, dest.cstring) != 0:
      raiseExcWithPath2(src, dst)
  proc symlink*[T](src, dst: PathLike[T], target_is_directory{.used.} = false, dir_fd: int) =
    ## target_is_directory is ignored.
    if c_symlinkat(src.cstring, dir_fd.cint, dst.cstring) != 0:
      raiseExcWithPath2(src, dst)

proc symlink*[T](src, dst: PathLike[T], target_is_directory = false) =
  # std/os createSymlink on Windows will raise OSError if 
  # SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE is not supported yet
  if os_symlink_impl($src, $dst, target_is_directory):
    raiseExcWithPath2(src, dst)

proc link*[T](src, dst: PathLike[T]) =
  pathsAsOne(src, dst).tryOsOp:
    createHardlink($src, $dst)
