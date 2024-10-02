
import ../common

when InJs:
  proc rmdirSync(path: cstring){.importNode(fs, rmdirSync).}
  proc mkdirSync(path: cstring, mode: cint){.importNode(fs, mkdirSync).}
  proc rawRemoveDir*(dp: PathLike) =
    let cs = cstring $dp
    catchJsErrAndRaise:
      rmdirSync(cs)
  proc rawCreateDir*(dp: PathLike, mode=0o777) =
    let cs = cstring($dp)
    catchJsErrAndRaise:
      mkdirSync(cs, cint mode)

else:
  include ./ncommon
  when defined(windows):
    template wrapUnary*(varname, winApiProc, arg: untyped) =
      var varname = winApiProc(newWideCString(arg))
  else:
    proc mkdir(s: string, mode: int): int32 =
      mkdir(s.cstring, mode.Mode)

  # from nim-2.1.2 lib/std/private/osdirs.nim#L329
  # but `raise FileNotFoundError` when shall and change param
  proc rawRemoveDir*(dp: PathLike) {.noWeirdTarget.} =
    let dir = $dp
    when defined(windows):
      wrapUnary(res, removeDirectoryW, dir)
      if res == 0'i32:
        dp.raiseExcWithPath()
    else:
      if rmdir(cstring dir) != 0'i32:
        dp.raiseExcWithPath()

  # from nim-2.1.2 lib/std/private/osdirs.nim#L364
  # but raise FileNotFoundError and FileExistsError when shall and change param
  proc rawCreateDir*(dp: PathLike, mode=0o777) =
    # Try to create one directory (not the whole path).
    #
    # This is a thin wrapper over mkDir (or alternatives on other systems),
    # so in case of a pre-existing path we don't check that it is a directory.
    let dir = $dp
    when defined(solaris):
      let res = mkdir(dir, mode)
      if res != 0'i32:
        dp.raiseExcWithPath()
    elif defined(haiku) or defined(posix):
      let res = mkdir(dir, mode)
      if res != 0'i32:
        dp.raiseExcWithPath()
    else:
      # TODO: consider mode as Python does.
      wrapUnary(res, createDirectoryW, dir)

      if res == 0'i32:  # res is in fact of `BOOL`
        dp.raiseExcWithPath()
