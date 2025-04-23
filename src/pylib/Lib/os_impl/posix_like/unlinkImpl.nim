
import ../common
include ./ncommon
export common


when InJs:
  proc unlinkSync(path: cstring){.importNode(fs, unlinkSync).}
  proc unlinkImpl*(p: PathLike) =
    let cs = cstring $p
    catchJsErrAndRaise:
      unlinkSync cs
    #[ XXX: NIM-BUG: if as follows, when JS, 
      Error: internal error: genTypeInfo(tyUserTypeClassInst)
    catchJsErrAndRaise:
      unlinkSync(cstring($p))
    ]#
else:
  when defined(windows):
    import ../util/mywinlean
    type
      GET_FILEEX_INFO_LEVELS = enum
        GetFileExInfoStandard = cint 0
        GetFileExMaxInfoLevel = cint 1
      WIN32_FILE_ATTRIBUTE_DATA{.importc, header: "<fileapi.h>",
          incompleteStruct.} = object
        dwFileAttributes: mywinlean.DWORD

    proc GetFileAttributesExW(lpFileName: LPCWSTR, fInfoLevelId: GET_FILEEX_INFO_LEVELS,
      lpFileInformation: pointer): BOOL{.importc, header: "<fileapi.h>".}
    proc Py_DeleteFileW*(lpFileName: LPCWSTR): BOOL =
      var info: WIN32_FILE_ATTRIBUTE_DATA
      var find_data: WIN32_FIND_DATAW
      var is_directory = false
      var is_link = false

      if GetFileAttributesExW(lpFileName, GetFileExInfoStandard, addr info):
        is_directory = bool info.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY

        # Get WIN32_FIND_DATA structure for the path to determine if it is a symlink
        if is_directory and (info.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0:
          let find_data_handle = FindFirstFileW(lpFileName, find_data)

          if find_data_handle != INVALID_HANDLE_VALUE:
            # IO_REPARSE_TAG_SYMLINK if it is a symlink and
            # IO_REPARSE_TAG_MOUNT_POINT if it is a junction point.
            is_link = (find_data.dwReserved0 == IO_REPARSE_TAG_SYMLINK) or
                      (find_data.dwReserved0 == IO_REPARSE_TAG_MOUNT_POINT)
            FindClose(find_data_handle)

      if is_directory and is_link:
        return BOOL removeDirectoryW(lpFileName)

      return BOOL deleteFileW(lpFileName)

  # from nim-2.1.2/lib/std/private/osfiles.nim `proc tryRemoveFile`
  proc unlinkAux[T](p: PathLike[T]
    ): bool {.noWeirdTarget.} =
    ## Removes the file at `p`.
    ##
    ## If this fails, returns `false`.
    ## This raises `FileNotFoundError`
    ## if the file never existed.
    ##
    ## On Windows, ignores the read-only attribute.
    ##
    let file = $p
    when defined(windows):
      let f = newWideCString(file)
      if Py_DeleteFileW(f) != 0:  ## returns TRUE
        return true
    else:
      if unlink(cstring file) == 0'i32: return true  # success
  proc unlinkImpl*(p: PathLike) =
    if not unlinkAux(p):
      p.raiseExcWithPath()