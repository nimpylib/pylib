## pycore_fileutils_windows.h

import ./mywinlean
import std/dynlib

type
  FILE_STAT_BASIC_INFORMATION* = object
    FileId*: LARGE_INTEGER
    CreationTime*, LastAccessTime*, LastWriteTime*, ChangeTime*: LARGE_INTEGER
    AllocationSize*, EndOfFile*: LARGE_INTEGER
    FileAttributes*: ULONG
    ReparseTag*: ULONG
    NumberOfLinks*: ULONG
    DeviceType*, DeviceCharacteristics*: ULONG
    Reserved: ULONG
    VolumeSerialNumber*: LARGE_INTEGER
    FileId128*: FILE_ID_128

  FileInfoByNameClass* = enum
    # Define the enum values corresponding to FILE_INFO_BY_NAME_CLASS
    # Add the appropriate values here based on your use case.
    FileStatByNameInfo = cint(0)
    FileStatLxByNameInfo
    FileCaseSensitiveByNameInfo
    FileStatBasicByNameInfo
    MaximumFileInfoByNameClass

  PGetFileInformationByName = proc(
    FileName: WideCString,
    FileInformationClass: FileInfoByNameClass,
    FileInfoBuffer: pointer,
    FileInfoBufferSize: ULONG
  ): bool {.stdcall.}

var
  GetFileInformationByName: PGetFileInformationByName = nil
  GetFileInformationByNameInit: int = -1

proc Py_GetFileInformationByName*(
  FileName: WideCString,
  FileInformationClass: FileInfoByNameClass,
  FileInfoBuffer: pointer,
  FileInfoBufferSize: ULONG
): bool =
  if GetFileInformationByNameInit < 0:
    let hMod = loadLib("api-ms-win-core-file-l2-1-4")
    GetFileInformationByNameInit = 0
    if hMod != nil:
      GetFileInformationByName = cast[PGetFileInformationByName](symAddr(hMod, "GetFileInformationByName"))
      if GetFileInformationByName != nil:
        GetFileInformationByNameInit = 1
      else:
        unloadLib(hMod)

  if GetFileInformationByNameInit <= 0:
    SetLastError(ERROR_NOT_SUPPORTED)
    return false

  return GetFileInformationByName(FileName, FileInformationClass, FileInfoBuffer, FileInfoBufferSize)
