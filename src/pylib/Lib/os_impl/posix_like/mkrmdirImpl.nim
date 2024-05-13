
import ../common

const weirdTarget = defined(nimscript) or defined(js)

when weirdTarget:
  discard
elif defined(windows):
  import std/[winlean]
elif defined(posix):
  import std/[posix]


when defined(windows) and not weirdTarget:
  template wrapUnary*(varname, winApiProc, arg: untyped) =
    var varname = winApiProc(newWideCString(arg))

when weirdTarget:
  {.pragma: noWeirdTarget, error: "this proc is not available on the NimScript/js target".}
else:
  {.pragma: noWeirdTarget.}

# from nim-2.1.2 lib/std/private/osdirs.nim#L329
# but raise FileNotFoundError when shall and change param
proc rawRemoveDir*(dp: PathLike) {.noWeirdTarget.} =
  let dir = $dp
  when defined(windows):
    wrapUnary(res, removeDirectoryW, dir)
    let lastError = osLastError()
    if res == 0'i32:
      case lastError.int32
      of 2'i32, 3'i32:
        raiseFileNotFoundError dp
      of 18'i32:
        discard  # (See L334) why slience ERROR_NO_MORE_FILES?
        # Is ever this error possible when `removeDirectory`?
      else:
        raiseOSError(lastError, dir)
  else:
    if rmdir(dir) != 0'i32: 
      if errno == ENOENT: 
        raiseFileNotFoundError dp
      else:
        raiseOSError(osLastError(), dir)

when not weirdTarget and not defined(windows):
  proc mkdir(s: string, mode: int) =
    mkdir(s.cstring, mode.Mode)
# from nim-2.1.2 lib/std/private/osdirs.nim#L364
# but raise FileNotFoundError and FileExistsError when shall and change param
proc rawCreateDir*(dp: PathLike, mode=0o777) {.noWeirdTarget.} =
  # Try to create one directory (not the whole path).
  # returns `true` for success, `false` if the path has previously existed
  #
  # This is a thin wrapper over mkDir (or alternatives on other systems),
  # so in case of a pre-existing path we don't check that it is a directory.
  let dir = $dp
  when defined(solaris):
    let res = mkdir(dir, mode)
    if res != 0'i32:
      if errno in {EEXIST, ENOSYS}:
        raiseFileExistsError dp
      elif errno == ENOENT:
        raiseFileNotFoundError dp
      else:
        raiseOSError(osLastError(), dir)
  elif defined(haiku) or defined(posix):
    let res = mkdir(dir, mode)
    if res != 0'i32:
      if errno == EEXIST:
        raiseFileExistsError dp
      elif errno == ENOENT:
        raiseFileNotFoundError dp
      else:
        # when haiku, may raise EROFS
        raiseOSError(osLastError(), dir)
  else:
    # TODO: consider mode as Python does.
    wrapUnary(res, createDirectoryW, dir)

    if res == 0'i32:  # res is in fact of `BOOL`
      case getLastError()
      of 183'i32: # ERROR_ALREADY_EXISTS
        raiseFileExistsError dp
      of 2'i32, 3'i32:
        raiseFileNotFoundError dp
      else:
        raiseOSError(osLastError(), dir)
