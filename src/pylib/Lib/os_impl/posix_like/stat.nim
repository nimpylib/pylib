
from std/os import raiseOSError, osLastError

import ../common
import ./pyCfg
import ../util/handle_signal

importConfig [
  stats,
  os
]
when InJS:
  template decl(f, val) =
    const `HAVE f` = val
  decl lstat, true
  decl fstatat, false

const NO_FOLLOW_SYMLINKS = not (HAVE_FSTATAT or HAVE_LSTAT or useMS_WINDOWSproc)
import ./chkarg
import std/macros


#[ XXX: extact from CPython-3.13-alpha/Modules/posix L1829
  /* The CRT of Windows has a number of flaws wrt. its stat() implementation:
   - time stamps are restricted to second resolution
   - file modification times suffer from forth-and-back conversions between
     UTC and local time
   Therefore, we implement our own stat, based on the Win32 API directly.
*/
TODO: impl our own stat... Get rid of `_wstat`
]#

const DWin = defined(windows)
when InJs:
  import std/jsffi
  import ./jsStat
  template impStatTAttr[T](attr; dstAttr; cvt: typed) =
    func attr*(self: Stat): T =
      let res = self.dstAttr
      if res.isNull:
        raise newException(AttributeError,
          "'os.stat_result' object has no attribute '" & astToStr(attr) & '\'')
      result = cvt[T] res
  template jsToT[T](jsObj: JsObject): T = jsObj.to T
  template impStatTAttr[T](attr; dstAttr) =
    impStatTAttr[T](attr, dstAttr, jsToT)

  template impStatIAttr(attr; dstAttr; typ) =
    type typ = cdouble
    impStatTAttr[typ](attr, dstAttr)
  template impStatIAttr(attr; dstAttr) = impStatTAttr[cdouble](attr, dstAttr)
  impStatIAttr st_ino,    ino,    Ino
  impStatIAttr st_mode,   mode,   Mode
  impStatIAttr st_nlink,  nlink,  Nlink
  impStatIAttr st_uid,    uid,    Uid
  impStatIAttr st_gid,    gid,    Gid
  impStatIAttr st_dev,    dev,    Dev
  impStatIAttr st_rdev,   rdev
  impStatIAttr st_size,   size,   Off
  impStatIAttr st_blocks, blocks, Blkcnt
  impStatIAttr st_blksize,blksize,Blksize

  func rawValueOf(obj: Date): c_double{.importjs: "(#).valueOf()".}
  template chkDate(obj: Date) =
    if obj.isNull:  # may be null on some platform
      raise newException(OSError,
        "get date from stat_result is supported in your platform")
  func dateToSec(obj: Date): float =
    # the number of milliseconds for this date since the epoch
    chkDate obj
    obj.rawValueOf().float / 1000
  func dateToNs(obj: Date): BiggestInt =
    chkDate obj
    BiggestInt obj.rawValueOf()


else:
  when DWin:
    import ../util/[
      mywinlean, getFileInfo]
    import ../../../pyerrors/oserr/PC_errmap
    import ./errnoUtils
    import ../../n_stat
    import ../../stat_impl/consts except FILE_ATTRIBUTE_DIRECTORY,
      BY_HANDLE_FILE_INFORMATION, FILE_ATTRIBUTE_REPARSE_POINT
    #type Time64 = int64
    when defined(nimPreviewSlimSystem):
      import std/widestrs
    type
      Dev = uint64
      Ino = uint64
      Mode = cushort
      Nlink = cuint  ## CPython uses cint, but BY_HANDLE_FILE_INFORMATION.nNumberOfLinks is unsigned
      Uid = cint
      Gid = cint
      Rdev = uint32
      Size = int64
      Time{.importc: "time_t", header: "<time.h>".} = int64  ## int32 ifdef _USE_32BIT_TIME_T
      Nsec = cint
      FileAttributes = uint32
      ReparseTag = uint32
      InoHigh = uint64

      Stat = object
        st_dev*: Dev
        st_ino*: Ino
        st_mode*: Mode
        st_nlink*: Nlink
        st_uid*: Uid
        st_gid*: Gid
        st_rdev*: Rdev
        st_size*: Size
        st_atime*: Time
        st_atime_nsec*: Nsec
        st_mtime*: Time
        st_mtime_nsec*: Nsec
        st_ctime*: Time
        st_ctime_nsec*: Nsec
        st_birthtime*: Time
        st_birthtime_nsec*: Nsec
        st_file_attributes*: FileAttributes
        st_reparse_tag*: ReparseTag
        st_ino_high: InoHigh
  else:
    import std/posix
  
  when HAVEfstatatRUNTIME and not declared(fstatat):
    proc fstatat(dir_fd: cint, path: cstring, st: var Stat,
               flag: cint): cint{.importc, header: "<fcntl.h>".}
    template fstatat(dir_fd: int, path: cstring, st: var Stat,
        flag: int): cint =
      fstatat(cint dir_fd, path, st, cint flag)

type
  stat_result* = ref object
    data*: Stat ## inner, used by `getattr` of `stat_result`

macro genTimeGetter(amc: static[char]) =
  result = newStmtList()
  let
    js_s_xtime = amc & "time"
    js_xtime = ident js_s_xtime
    js_getxtime = ident("get" & js_s_xtime)
  let s_st_xtim = "st_" & amc & "tim"
  let
    xtim = ident s_st_xtim
    xtime = ident(s_st_xtim & 'e')
  let
    xtime_ns = ident(s_st_xtim & "e_ns")
  result = quote do:
    when InJs:
      func `js_getxtime`*(s: Stat): float =
        ## inner, used by os.path
        s.`js_xtime`.dateToSec()
    func `xtime`*(self: stat_result): float =
      when InJs:
        `js_getxtime` self.data
      else:
        when compiles(self.data.`xtim`):
          self.data.`xtim`.tv_sec.float + self.data.`xtim`.tv_nsec/1_000_000_000
        else:
          self.data.`xtime`.float
    func `xtime_ns`*(self: stat_result): BiggestInt{.pysince(3,3).} =
      when InJs:
        self.data.`js_xtime`.dateToNs()
      else:
        when compiles(self.data.`xtim`):
          self.data.`xtim`.tv_sec.BiggestInt * 1_000_000_000 +
          self.data.`xtim`.tv_nsec.BiggestInt
        else:
          self.data.`xtime`.BiggestInt * 1_000_000_000

genTimeGetter 'a'
genTimeGetter 'm'
genTimeGetter 'c'

{.experimental: "dotOperators".}
template `.`*(self: stat_result; attr): untyped =
  ## as Python's `__getattr__`
  self.data.attr

const visible_size = 10

func getitem(self: stat_result, i: int): BiggestInt =
  # this proc was once generated by macro
  case i
  of 0: result = BiggestInt self.data.st_ino
  of 1: result = BiggestInt self.data.st_mode
  of 2: result = BiggestInt self.data.st_nlink
  of 3: result = BiggestInt self.data.st_uid
  of 4: result = BiggestInt self.data.st_gid
  of 5: result = BiggestInt self.data.st_dev
  of 6: result = BiggestInt self.data.st_size
  of 7: result = BiggestInt self.st_atime
  of 8: result = BiggestInt self.st_mtime
  of 9: result = BiggestInt self.st_ctime
  else:
    raise newException(IndexDefect, "tuple index out of range")

func `[]`*(self: stat_result, i: int): BiggestInt =
  self.getitem(if i < 0: visible_size + i else: i)

func to_result(s: sink Stat): stat_result =
  result = stat_result(data: s)

when InJs:
  proc statAux(st: var Stat, path: int|string) =
    catchJsErrAndRaise:
      st =
        when path is int:
          fstatSync(path.cint)
        else:
          let cs = cstring(path)
          statSync(cs)
  proc fstatAux(st: var Stat, fd: int) =
    catchJsErrAndRaise:
      st = fstatSync(fd.cint)
  proc lstatAux(st: var Stat, path: PathLike) =
    catchJsErrAndRaise:
      st = block:
        let cs = cstring($path)
        lstatSync(cs)

template statAttr*(path: PathLike|int, attr: untyped): untyped =
  ## stat(`path`).`attr`
  var st{.noinit.}: Stat
  statAux st, path
  st.attr


when DWin:
  const secs_between_epochs = 11644473600'i64 # Seconds between 1.1.1601 and 1.1.1970

  proc FILE_TIME_to_time_t_nsec(in_ptr: FILETIME, time_out: var Time, nsec_out: var cint) =
    let i = cast[int64](in_ptr)
    nsec_out = cint((i mod 10_000_000) * 100) # FILETIME is in units of 100 nsec.
    time_out = Time((i div 10_000_000) - secs_between_epochs)

  proc LARGE_INTEGER_to_time_t_nsec(in_ptr: LARGE_INTEGER, time_out: var Time, nsec_out: var cint) =
    nsec_out = cint((in_ptr.QuadPart mod 10_000_000) * 100) # FILETIME is in units of 100 nsec.
    time_out = Time((in_ptr.QuadPart div 10_000_000) - secs_between_epochs)


  template M(i): Mode = cast[Mode](i)
  proc attributes_to_mode(attr: DWORD): Mode =
    result =
      if (attr and DWORD FILE_ATTRIBUTE_DIRECTORY) != 0:
        result or S_IFDIR.M or 0o111 # IFEXEC for user, group, other
      else:
        result or S_IFREG.M
    result =
      if (attr and DWORD FILE_ATTRIBUTE_READONLY) != 0:
        result or 0o444
      else:
        result or 0o666


  type id_128_to_ino = object
    case split: bool
    of false:
      id: FILE_ID_128
    of true:
      st_ino: uint64
      st_ino_high: uint64

  proc Py_attribute_data_to_stat(info: var BY_HANDLE_FILE_INFORMATION, reparse_tag: ULONG,
                  basic_info: ptr FILE_BASIC_INFO, id_info: ptr FILE_ID_INFO,
                  result: var Stat) =

    result = Stat()
    result.st_mode = attributes_to_mode(info.dwFileAttributes)
    result.st_size = (int64(info.nFileSizeHigh) shl 32) + int64(info.nFileSizeLow)
    result.st_dev = (if not id_info.isNil: id_info.VolumeSerialNumber.Dev else: info.dwVolumeSerialNumber.Dev)
    #result.st_rdev = 0

    if not basic_info.isNil:
      LARGE_INTEGER_to_time_t_nsec(basic_info.CreationTime, result.st_birthtime, result.st_birthtime_nsec)
      LARGE_INTEGER_to_time_t_nsec(basic_info.ChangeTime, result.st_ctime, result.st_ctime_nsec)
      LARGE_INTEGER_to_time_t_nsec(basic_info.LastWriteTime, result.st_mtime, result.st_mtime_nsec)
      LARGE_INTEGER_to_time_t_nsec(basic_info.LastAccessTime, result.st_atime, result.st_atime_nsec)
    else:
      FILE_TIME_to_time_t_nsec(info.ftCreationTime, result.st_birthtime, result.st_birthtime_nsec)
      FILE_TIME_to_time_t_nsec(info.ftLastWriteTime, result.st_mtime, result.st_mtime_nsec)
      FILE_TIME_to_time_t_nsec(info.ftLastAccessTime, result.st_atime, result.st_atime_nsec)

    result.st_nlink = info.nNumberOfLinks

    if not id_info.isNil:
      var file_id: id_128_to_ino
      file_id.id = id_info.FileId
      file_id.split = true
      result.st_ino = file_id.st_ino
      result.st_ino_high = file_id.st_ino_high

    if result.st_ino == 0 and result.st_ino_high == 0:
      result.st_ino = (uint64(info.nFileIndexHigh) shl 32) + uint64(info.nFileIndexLow)

    if (info.dwFileAttributes and DWORD FILE_ATTRIBUTE_REPARSE_POINT) != 0 and (reparse_tag == ULONG IO_REPARSE_TAG_SYMLINK):
      result.st_mode = (result.st_mode and not Mode S_IFMT_val) or S_IFLNK.Mode

    result.st_file_attributes = info.dwFileAttributes

  proc Py_stat_basic_info_to_stat(info: var FILE_STAT_BASIC_INFORMATION, result: var Stat) =
    result = Stat()
    result.st_mode = attributes_to_mode(info.FileAttributes)
    result.st_size = info.EndOfFile.QuadPart
    LARGE_INTEGER_to_time_t_nsec(info.CreationTime, result.st_birthtime, result.st_birthtime_nsec)
    LARGE_INTEGER_to_time_t_nsec(info.ChangeTime, result.st_ctime, result.st_ctime_nsec)
    LARGE_INTEGER_to_time_t_nsec(info.LastWriteTime, result.st_mtime, result.st_mtime_nsec)
    LARGE_INTEGER_to_time_t_nsec(info.LastAccessTime, result.st_atime, result.st_atime_nsec)
    result.st_nlink = info.NumberOfLinks
    result.st_dev = info.VolumeSerialNumber.QuadPart.Dev

    var file_id: id_128_to_ino
    file_id.id = info.FileId128
    file_id.split = true
    result.st_ino = file_id.st_ino
    result.st_ino_high = file_id.st_ino_high

    result.st_reparse_tag = info.ReparseTag
    if (info.FileAttributes and DWORD FILE_ATTRIBUTE_REPARSE_POINT) != 0 and
        info.ReparseTag == ULONG IO_REPARSE_TAG_SYMLINK:
      result.st_mode = (result.st_mode and not Mode S_IFMT_val) or S_IFLNK.Mode

    result.st_file_attributes = info.FileAttributes

    case info.DeviceType
    of FILE_DEVICE_DISK, FILE_DEVICE_VIRTUAL_DISK, FILE_DEVICE_DFS,
        FILE_DEVICE_CD_ROM, FILE_DEVICE_CONTROLLER, FILE_DEVICE_DATALINK:
      discard
    of FILE_DEVICE_DISK_FILE_SYSTEM, FILE_DEVICE_CD_ROM_FILE_SYSTEM, FILE_DEVICE_NETWORK_FILE_SYSTEM:
      result.st_mode = (result.st_mode and not Mode S_IFMT_val) or 0x6000.Mode
    of FILE_DEVICE_CONSOLE, FILE_DEVICE_NULL, FILE_DEVICE_KEYBOARD,
        FILE_DEVICE_MODEM, FILE_DEVICE_MOUSE, FILE_DEVICE_PARALLEL_PORT,
        FILE_DEVICE_PRINTER, FILE_DEVICE_SCREEN, FILE_DEVICE_SERIAL_PORT,
        FILE_DEVICE_SOUND:
      result.st_mode = (result.st_mode and not Mode S_IFMT_val) or S_IFCHR.Mode
    of FILE_DEVICE_NAMED_PIPE:
      result.st_mode = (result.st_mode and not Mode S_IFMT_val) or S_IFIFO.Mode
    else:
      if (info.FileAttributes and DWORD FILE_ATTRIBUTE_DIRECTORY) != 0:
        result.st_mode = (result.st_mode and not Mode S_IFMT_val) or S_IFDIR.Mode

when DWin:
  proc findDataToFileInfo(pFileData: WIN32_FIND_DATAW,
                          info: var BY_HANDLE_FILE_INFORMATION,
                          reparseTag: var ULONG) =
    info = BY_HANDLE_FILE_INFORMATION()
    info.dwFileAttributes = pFileData.dwFileAttributes
    info.ftCreationTime = pFileData.ftCreationTime
    info.ftLastAccessTime = pFileData.ftLastAccessTime
    info.ftLastWriteTime = pFileData.ftLastWriteTime
    info.nFileSizeHigh = pFileData.nFileSizeHigh
    info.nFileSizeLow = pFileData.nFileSizeLow
    if (pFileData.dwFileAttributes and DWORD FILE_ATTRIBUTE_REPARSE_POINT) != 0:
      reparseTag = pFileData.dwReserved0
    else:
      reparseTag = 0

  template `==`(wc: Utf16Char, c: char): bool = cast[uint16](wc) == uint16(c)
  template L(c: char): Utf16Char = Utf16Char(c)
  template L(s: string): WideCString = newWideCString(s)
  proc attributesFromDir(pszFile: WideCString,
                         info: var BY_HANDLE_FILE_INFORMATION,
                         reparseTag: var ULONG): bool =
    var hFindFile: HANDLE
    var fileData: WIN32_FIND_DATAW
    var filename = pszFile
    var n = pszFile.len
    if n > 0 and (pszFile[n - 1] == '\\' or pszFile[n - 1] == '/'):
      filename = cast[WideCString](alloc((n + 1) * sizeof(filename[0])))
      if filename.isNil:
        setLastError(ERROR_NOT_ENOUGH_MEMORY)
        return false
      copyMem(filename, pszFile, n+1)
      while n > 0 and (filename[n - 1] == '\\' or filename[n - 1] == '/'):
        filename[n - 1] = L'\0'
        dec n
      if n == 0 or (n == 1 and filename[1] == ':'):
        dealloc(filename)
        return false
    hFindFile = FindFirstFileW(filename, fileData)
    if pszFile != filename:
      dealloc(filename)
    if hFindFile == INVALID_HANDLE_VALUE:
      return false
    FindClose(hFindFile)
    findDataToFileInfo(fileData, info, reparseTag)
    return true

  proc wcsrchr(wcs: WideCString, c: Utf16Char): WideCString{.importc, header: "<wchar.h>".}
  proc wcsicmp(s1, s2: WideCString): int{.importc, header: "<wchar.h>".}

  proc updateStModeFromPath(path: LPCWSTR, attr: DWORD,
                            status: var Stat) =
    if (attr and DWORD FILE_ATTRIBUTE_DIRECTORY) == 0:
      let fileExtension = wcsrchr(path, L'.')
      if not fileExtension.isNil:
        if wcsicmp(fileExtension, L".exe") == 0 or
           wcsicmp(fileExtension, L".bat") == 0 or
           wcsicmp(fileExtension, L".cmd") == 0 or
           wcsicmp(fileExtension, L".com") == 0:
          status.st_mode = status.st_mode or 0o111

  proc win32_xstat_slow_impl(path: LPCWSTR, status: var Stat,
                          traverse: bool): cint =

    var traverse = traverse

    var hFile: HANDLE
    var fileInfo: BY_HANDLE_FILE_INFORMATION
    var basicInfo: FILE_BASIC_INFO
    var pBasicInfo: ptr FILE_BASIC_INFO = nil
    var idInfo: FILE_ID_INFO
    var pIdInfo: ptr FILE_ID_INFO = nil
    var tagInfo: FILE_ATTRIBUTE_TAG_INFO
    var fileType, error: DWORD
    var isUnhandledTag = false
    var retval = cint 0
    template goto_cleanup =
      if hFile != INVALID_HANDLE_VALUE:
        error = if retval != 0: GetLastError() else: 0
        if CloseHandle(hFile) == 0:
          retval = -1
        elif retval != 0:
          SetLastError(error)
      return retval

    var access = DWORD FILE_READ_ATTRIBUTES
    var flags = DWORD FILE_FLAG_BACKUP_SEMANTICS
    if not traverse:
      flags = flags or DWORD FILE_FLAG_OPEN_REPARSE_POINT

    hFile = CreateFileW(path, access, 0, nil, OPEN_EXISTING, flags, NULL)
    if hFile == INVALID_HANDLE_VALUE:
      error = GetLastError()
      case error
      of ERROR_ACCESS_DENIED, ERROR_SHARING_VIOLATION:
        if not attributesFromDir(path, fileInfo, tagInfo.ReparseTag):
          return -1
      of ERROR_INVALID_PARAMETER:
        hFile = CreateFileW(path, access or GENERIC_READ,
                            FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                            OPEN_EXISTING, flags, NULL)
        if hFile == INVALID_HANDLE_VALUE:
          return -1
      of ERROR_CANT_ACCESS_FILE:
        if traverse:
          traverse = false
          isUnhandledTag = true
          hFile = CreateFileW(path, access, 0, nil, OPEN_EXISTING,
                              flags or FILE_FLAG_OPEN_REPARSE_POINT, NULL)
        if hFile == INVALID_HANDLE_VALUE:
          return -1
      else:
        return -1

    if hFile != INVALID_HANDLE_VALUE:
      fileType = GetFileType(hFile)
      if fileType != FILE_TYPE_DISK:
        if fileType == FILE_TYPE_UNKNOWN and getLastError() != 0:
          retval = -1
          goto_cleanup
        let fileAttributes = GetFileAttributesW(path)
        status = Stat()
        if fileAttributes != INVALID_FILE_ATTRIBUTES and
           (fileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0:
          status.st_mode = M S_IFDIR
        elif fileType == FILE_TYPE_CHAR:
          status.st_mode = M S_IFCHR
        elif fileType == FILE_TYPE_PIPE:
          status.st_mode = M S_IFIFO
        goto_cleanup

      if not traverse:
        if not GetFileInformationByHandleEx(hFile, FILE_INFO_BY_HANDLE_CLASS.FileAttributeTagInfo,
                                            tagInfo):
          retval = -1
          goto_cleanup

      if not GetFileInformationByHandle(hFile, fileInfo) or
         not GetFileBasicInformationByHandleEx(hFile, basicInfo):
        retval = -1
        goto_cleanup

      pBasicInfo = addr basicInfo
      if GetFileInformationByHandleEx(hFile, FILE_INFO_BY_HANDLE_CLASS.FileIdInfo, idInfo):
        pIdInfo = addr idInfo

    Py_attribute_data_to_stat(fileInfo, tagInfo.ReparseTag, pBasicInfo, pIdInfo, status)
    updateStModeFromPath(path, fileInfo.dwFileAttributes, status)

    goto_cleanup


  proc win32_xstat_impl(path: LPCWSTR, status: var Stat, traverse: bool): cint =
    var statInfo: FILE_STAT_BASIC_INFORMATION
    if Py_GetFileInformationByName(path, FileStatBasicByNameInfo, addr statInfo, sizeof(statInfo).DWORD):
      if (statInfo.FileAttributes and DWORD FILE_ATTRIBUTE_REPARSE_POINT) == 0 or
        (not traverse and IsReparseTagNameSurrogate(statInfo.ReparseTag)):
        Py_stat_basic_info_to_stat(statInfo, status)
        updateStModeFromPath(path, statInfo.FileAttributes, status)
        return 0
    else:
      case GetLastError()
      of ERROR_FILE_NOT_FOUND, ERROR_PATH_NOT_FOUND, ERROR_NOT_READY, ERROR_BAD_NET_NAME:
        # These errors aren't worth retrying with the slow path
        return -1
      #of ERROR_NOT_SUPPORTED: # Indicates the API couldn't be loaded
      else:
        discard

    return win32_xstat_slow_impl(path, status, traverse)

  proc win32_xstat(path: WideCString, status: var Stat, traverse: bool): cint =
    #[Protocol violation: we explicitly clear errno, instead of
      setting it to a POSIX error. Callers should use GetLastError.]#
    result = win32_xstat_impl(path, status, traverse)
    setErrno0

    # ctime is only deprecated from 3.12, so we copy birthtime across
    status.st_ctime = status.st_birthtime
    status.st_ctime_nsec = status.st_birthtime_nsec

template def3STAT(S, L, F){.dirty.} =
  template  STATf(p: string, s): cint= S
  template LSTAT(p: string, s): cint = L
  template FSTAT(p: int, s): cint = F


when DWin:
  def3STAT(
    win32_xstat(newWideCString p, s, true),
    win32_xstat(newWideCString p, s, false),
    Py_fstat_noraise(p, s),
  )
elif InJs:
  template ret0(body): cint =
    body
    0
  def3STAT(
    ret0 statAux(s, p),
    ret0 lstatAux(s, p),
    ret0 fstatAux(s, p),
  )
else:
  def3STAT(
     posix.stat(cstring p, s),
     posix.lstat(cstring p, s),
     posix.fstat(cint p, s),
  )

proc Py_fstat_noraise*(fd: int, status: var Stat): cint =
  ## EXT.
  ## 
  ## fileutils.c `_Py_fstat_noraise`
  when DWin:
    var
      info: BY_HANDLE_FILE_INFORMATION
      basicInfo: FILE_BASIC_INFO
      idInfo: FILE_ID_INFO
      pIdInfo = addr idInfo
      
      h = Py_get_osfhandle_noraise(fd)

    if h == INVALID_HANDLE_VALUE:
      #[ errno is already set by _get_osfhandle, but we also set
          the Win32 error for callers who expect that]#
      setLastError ERROR_INVALID_HANDLE
      return -1

    status = Stat()

    let typ = GetFileType(h)
    if typ == FILE_TYPE_UNKNOWN:
      let error = cint getLastError()
      if error != 0:
        setErrnoRaw winerror_to_errno error
        return -1
      # else: valid but unknown file
    
    if typ != FILE_TYPE_DISK:
      if typ == FILE_TYPE_CHAR:
        status.st_mode = M S_IFCHR
      elif typ == FILE_TYPE_PIPE:
        status.st_mode = M S_IFIFO
      return 0
    
    if GetFileInformationByHandle(h, info) == FALSE or
      !GetFileBasicInformationByHandleEx(h, basicInfo):
      #[The Win32 error is already set, but we also set errno for
        callers who expect it]#
      setErrnoRaw winerror_to_errno cint getLastError()
      return -1

    if !GetFileBasicInformationByHandleEx(h, basicInfo):
      # Failed to get FileIdInfo, so do not pass it along
      pIdInfo = nil
    
    Py_attribute_data_to_stat(info, 0, addr basicInfo, pIdInfo, status)
    return 0
  elif InJS:
    int FSTAT(fd, status) 

proc Py_fstat*(fd: int, status: var Stat) =
  ## EXT.
  ## 
  ## fileutils.c `_Py_fstat`
  if Py_fstat_noraise(fd, status) != 0:
    raiseOSError osLastError()

proc do_stat_impl(result: var Stat; function_name: string, path: string|int, dir_fd: int, follow_symlinks: bool) =
  when HAVE_FSTATAT:
    var fstatat_unavailable = false
  var res: cint
  when NO_FOLLOW_SYMLINKS:
    if follow_symlinks_specified(function_name, follow_symlinks):
      return
  template doStat =
    res = STATf(path, result)
  template doFstatat =
    when HAVE_FSTATAT:
      if dir_fd != DEFAULT_DIR_FD or not follow_symlinks:
        when HAVE_FSTATAT_RUNTIME:
          res = fstatat(dir_fd, cstring path, result,
            if follow_symlinks: 0 else: AT_SYMLINK_NOFOLLOW)
        else:
          fstat_unavailable = true
      else:
        doStat()
    else:
      doStat()

  let path_fd = (when path is int: path else: -1)
  if function_name == "stat":
    if path_and_dir_fd_invalid("stat", path, dir_fd) or
        dir_fd_and_fd_invalid("stat", dir_fd, path_fd) or
        fd_and_follow_symlinks_invalid("stat", path_fd, follow_symlinks):
      return
  let path = (when path is int :"" else: path)
  if path_fd != -1:
    res = FSTAT(path_fd, result)
  else:
    when DWin:
      if follow_symlinks:
        res = STATf(path, result)
      else:
        res = LSTAT(path, result)
    else:
      when HAVE_LSTAT:
        if not follow_symlinks and dir_fd == DEFAULT_DIR_FD:
          res = LSTAT(path, result)
        else:
          doFstatat
      else:
        doFstatat

template withSt(body): stat_result{.dirty.} =
  bind to_result, Stat
  var st{.noinit.}: Stat
  body
  to_result st

proc do_stat(function_name: string, path: string|int, dir_fd = DEFAULT_DIR_FD, follow_symlinks = true): stat_result =
  withSt:
    st.do_stat_impl(function_name, path, dir_fd, follow_symlinks)

proc stat*[T](path: PathLike[T], dir_fd = DEFAULT_DIR_FD, follow_symlinks = true): stat_result =
  do_stat("stat", $path, dir_fd, follow_symlinks)

proc stat*(path: int, dir_fd = DEFAULT_DIR_FD, follow_symlinks = true): stat_result =
  do_stat("stat", path, dir_fd, follow_symlinks)

proc lstat*[T](path: PathLike[T], dir_fd = DEFAULT_DIR_FD): stat_result =
  do_stat("lstat", $path, dir_fd, false)


proc fstat*(fd: int): stat_result =
  let fd = cint fd
  var res: cint
  withSt:
    initVal_with_handle_signal(res, FSTAT(fd, st))
