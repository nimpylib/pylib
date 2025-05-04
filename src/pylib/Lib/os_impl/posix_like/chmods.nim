
import ../common
import ./errnoUtils
import ./pyCfg
importConfig [
  chmods,
  os
]
when InJs:
  template decl(f, val) =
    const `HAVE f` = val
  decl chmod, true
  decl fchmod, true
  decl lchmod, false
  decl fchmodat, false

when HAVE_FCHMODAT or not (HAVE_FCHMODAT or HAVE_FCHMOD or useMS_WINDOWSproc):
  import ./chkarg
when HAVE_FCHMOD:
  import ../util/handle_signal

when InJS:
  import ./chmodsJs as posix
  template raiseErrnoWithPath(path: string) =
    raiseErrnoWithPath(path, res)
elif not useMS_WINDOWSproc:
  import std/posix
  when Mode isnot int:
    template chmod(path: cstring, mode: int): cint = posix.chmod(path, Mode mode)
  when HAVEfchmodatRUNTIME and not declared(fchmodat):
    proc fchmodat(dir_fd: cint, path: cstring, mode: Mode, flag: cint): cint{.
      importc, header: "<sys/stat.h>".}
    template fchmodat(dir_fd: int, path: cstring, mode: int, flag: int): cint =
      fchmodat(cint dir_fd, path, Mode mode, flag)
else: # MS_WINDOWS and not JS
  import ../util/mywinlean
  import std/widestrs
  import ../../stat_impl/consts


  proc SetFileInformationByHandle(
    hfile: Handle, infoClass: FILE_INFO_BY_HANDLE_CLASS, lpBuffer: pointer, dwBufferSize: DWORD
  ): bool {.importc, header: "<fileapi.h>".}
  proc win32_lchmod(path: WideCString, mode: int): bool =
    var attr = GetFileAttributesW(path)
    if attr == INVALID_FILE_ATTRIBUTES:
      return false
    if (mode and S_IWRITE) != 0:
      attr = attr and (not FILE_ATTRIBUTE_READONLY)
    else:
      attr = attr or FILE_ATTRIBUTE_READONLY
    return SetFileAttributesW(path, attr) != 0

  proc win32_hchmod(hfile: Handle, mode: int): bool =
    var info: FILE_BASIC_INFO
    if not GetFileBasicInformationByHandleEx(hfile, info):
      return false
    if (mode and S_IWRITE) != 0:
      info.FileAttributes = info.FileAttributes and (not FILE_ATTRIBUTE_READONLY)
    else:
      info.FileAttributes = info.FileAttributes or FILE_ATTRIBUTE_READONLY
    return SetFileInformationByHandle(hfile, FILE_INFO_BY_HANDLE_CLASS.FileBasicInfo,
      addr info, DWORD sizeof(info))

  proc win32_fchmod(fd: int, mode: int): bool =
    let hfile = Py_get_osfhandle_noraise(fd)
    if hfile == INVALID_HANDLE_VALUE:
      setLastError(ERROR_INVALID_HANDLE)
      return false
    return win32_hchmod(hfile, mode)

template narrow(path: string): cstring = cstring path

proc chmod*(
    path: (when HAVE_FCHMODAT: string|int else: string),
    mode: int,
    dir_fd = DEFAULT_DIR_FD,
    follow_symlinks = not MS_WINDOWS) =
  when not (HAVE_FCHMODAT or HAVE_FCHMOD or useMS_WINDOWSproc):
    if follow_symlinks_specified(follow_symlinks):
      return
  sys.audit("os.chmod", path, mode, dir_fd)
  when useMS_WINDOWSproc:
    var res = false
    when path is int:
      if win32_fchmod(fd, mode):
        raiseExcWithPath path
    else:
      if follow_symlinks:
        let hfile = createFileW(newWideCString path,
          FILE_READ_ATTRIBUTES or FILE_WRITE_ATTRIBUTES,
          0, nil,
          OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
        if hfile != INVALID_HANDLE_VALUE:
          res = win32_hchmod(hfile, mode)
          discard closeHandle(hfile)
        else:
          res = win32_lchmod(newWideCString(path), mode)
    if not res:
      raiseErrnoWithPath path
  else:
    var res = cint(0)
    when HAVE_FCHMODAT:
      var fchmodat_unsupported, fchmodat_nofollow_unsupported = false
      let dir_fd_not_default = dir_fd != DEFAULT_DIR_FD
    template handleFchmodatRuntime() =
      when HAVE_FCHMODAT_RUNTIME:
        # fchmodat() doesn't currently support AT_SYMLINK_NOFOLLOW!
        # The documentation specifically shows how to use it,
        # and then says it isn't implemented yet.
        # (true on linux with glibc 2.15, and openindiana 3.x)
        #
        # Once it is supported, os.chmod will automatically
        # support dir_fd and follow_symlinks=False.  (Hopefully.)
        # Until then, we need to be careful what exception we raise.
        res = fchmodat(dir_fd, path.narrow, mode,
          if follow_symlinks: 0 else: AT_SYMLINK_NOFOLLOW)
        # But wait!  We can't throw the exception without allowing threads,
        # and we can't do that in this nested scope.  (Macro trickery, sigh.)
        fchmodat_nofollow_unsupported = res != 0 and
          ((isErr(ENOTSUP) or isErr(EOPNOTSUPP)) and
          not follow_symlinks)
      else:
        fchmodat_unsupported = true
        fchmodat_nofollow_unsupported = true
        res = -1

    template handleChmodFallback() =
      when HAVE_CHMOD:
        res = chmod(path.narrow, mode)
      elif defined(wasi):
        # WASI SDK 15.0 does not support chmod.
        # Ignore missing syscall for now.
        res = 0
      else:
        when defined(pylibForceRTErr):
          res = -1
          setErrno(ENOSYS)  # will raises OSError below
        else:
          static:assert false, "chmod not implement on you platform"

    template handleFchmodat() =
      when HAVE_FCHMODAT:
        if dir_fd_not_default or not follow_symlinks:
          handleFchmodatRuntime()
        else:
          handleChmodFallback()
      else:
        handleChmodFallback()

    template handleLchmodOrFchmod() =
      when HAVE_LCHMOD:
        if not follow_symlinks and not dir_fd_not_default:
          res = lchmod(path.narrow, mode)
        else:
          handleFchmodat()
      else:
        handleFchmodat()

    when HAVE_FCHMOD:
      when path is int:
        res = fchmod(path, mode)
      else:
        handleLchmodOrFchmod()
    else:
      handleLchmodOrFchmod()
    
    if res != 0:
      when HAVE_FCHMODAT:
        if fchmodat_unsupported and dir_fd_not_default:
          argument_unavailable_error("dir_fd")
        elif fchmodat_nofollow_unsupported:
          if not follow_symlinks and dir_fd_not_default:
            # dir_fd_and_follow_symlinks_invalid
            raise newException(ValueError,
              "chmod: cannot use dir_fd and follow_symlinks together")
          else:
            follow_symlinks_specified(follow_symlinks)
        else:
          raiseErrnoWithPath path
      else:
        raiseErrnoWithPath path

when HAVE_FCHMOD or useMS_WINDOWSproc:
  proc fchmod*(fd: int, mode: int) =
    sys.audit("os.chmod", fd, mode, -1)
    when useMS_WINDOWSproc:
      if not win32_fchmod(fd, mode):
        raiseErrno()
    else:
      var res: int
      initVal_with_handle_signal(res, posix.fchmod(cint fd, Mode mode))


when HAVE_LCHMOD or useMS_WINDOWSproc:
  proc lchmod*(path: string, mode: int) =
    sys.audit("os.chmod", path, mode, -1)
    when useMS_WINDOWSproc:
      if not win32_lchmod(newWideCString(path), mode):
        raiseErrnoWithPath path
    else:
      let res = lchmod(path, mode)
      if res < 0:
        raiseErrnoWithPath path
