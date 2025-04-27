
import std/winlean except DWORD, ULONG
export winlean except DWORD, ULONG,
  OPEN_EXISTING, FILE_SHARE_READ, FILE_SHARE_WRITE,
  FILE_FLAG_OPEN_REPARSE_POINT, FILE_ATTRIBUTE_DIRECTORY,
  FILE_ATTRIBUTE_READONLY, FILE_ATTRIBUTE_REPARSE_POINT,
  BY_HANDLE_FILE_INFORMATION, INVALID_FILE_ATTRIBUTES
import ./get_osfhandle
export get_osfhandle
type
  BOOL* = enum
    FALSE = cint 0
    TRUE = cint 1

converter toBool*(b: BOOL): bool = b != FALSE
template `!`*(b: BOOL): bool = b == FALSE

type
  LPCWSTR* = WideCString
  ULONG* = uint32
  DWORD* = uint32
  WORD* = uint16
  LARGE_INTEGER*{.pure, importc, header: "<winnt.h>".} = object
    ##[ We simplify the definition of LARGE_INTEGER, which is defined as:

- DWORD is uint32
- LONG is int32
- LONGLONG is int64

```c
typedef union _LARGE_INTEGER {
  struct {
    DWORD LowPart;
    LONG  HighPart;
  } DUMMYSTRUCTNAME;
  struct {
    DWORD LowPart;
    LONG  HighPart;
  } u;
  LONGLONG QuadPart;
} LARGE_INTEGER;
```
]##
    QuadPart*: int64
  FILE_BASIC_INFO*{.pure, importc, header: "<winbase.h>".} = object
    CreationTime*, LastAccessTime*, LastWriteTime*, ChangeTime*: LARGE_INTEGER
    FileAttributes*: DWORD

  FILE_ID_128*{.pure, importc, header: "<winnt.h>".} = object
    Identifier*: array[16, BYTE]
  FILE_ID_INFO*{.pure, importc, header: "<winbase.h>".} = object
    VolumeSerialNumber*: uint64
    FileId*: FILE_ID_128

  FILE_INFO_BY_HANDLE_CLASS*{.pure.} = enum
    FileBasicInfo = cint(0)  # to avoid conflict with FILE_BASIC_INFO type
    FileAttributeTagInfo = cint(9)

    FileIdInfo = cint(19)
    # ...

  WCHAR* = uint16

  WIN32_FIND_DATAW*{.importc, header: "<Windows.h>" # MinGW error if using <minwinbase.h>
  .} = object
    dwFileAttributes*: DWORD
    ftCreationTime*: FILETIME
    ftLastAccessTime*: FILETIME
    ftLastWriteTime*: FILETIME
    nFileSizeHigh*: DWORD
    nFileSizeLow*: DWORD
    dwReserved0*: DWORD
    dwReserved1*: DWORD
    cFileName*: array[MAX_PATH, WCHAR]
    cAlternateFileName*: array[14, WCHAR]
    dwFileType*: DWORD ## Obsolete. Do not use.
    dwCreatorType*: DWORD ## Obsolete. Do not use.
    wFinderFlags*: WORD ## Obsolete. Do not use.

  BY_HANDLE_FILE_INFORMATION*{.importc, header: "<fileapi.h>".} = object
    dwFileAttributes*: DWORD
    ftCreationTime*: FILETIME
    ftLastAccessTime*: FILETIME
    ftLastWriteTime*: FILETIME
    dwVolumeSerialNumber*: DWORD
    nFileSizeHigh*: DWORD
    nFileSizeLow*: DWORD
    nNumberOfLinks*: DWORD
    nFileIndexHigh*: DWORD
    nFileIndexLow*: DWORD

  FILE_ATTRIBUTE_TAG_INFO*{.importc, header: "<winbase.h>".} = object
    FileAttributes*, ReparseTag*: DWORD
const
  ERROR_INVALID_HANDLE* = 6
  ERROR_NOT_ENOUGH_MEMORY* = 8

  ERROR_NOT_READY* = 21
  ERROR_BAD_NET_NAME* = 67


  ERROR_SHARING_VIOLATION* = 32
  ERROR_NOT_SUPPORTED* = 50
  ERROR_INVALID_PARAMETER* = 87

  ERROR_CANT_ACCESS_FILE* = 110



  FILE_TYPE_CHAR* = 2
  FILE_TYPE_DISK* = 1
  FILE_TYPE_PIPE* = 3

  FILE_TYPE_UNKNOWN* = 0

  OPEN_EXISTING* = 3

  FILE_SHARE_READ* = 1
  FILE_SHARE_WRITE* = 2

  FILE_FLAG_OPEN_REPARSE_POINT* = 0x00200000

  FILE_DEVICE_CD_ROM* = 2
  FILE_DEVICE_CD_ROM_FILE_SYSTEM* = 3
  FILE_DEVICE_CONTROLLER* = 4
  FILE_DEVICE_DATALINK* = 5
  FILE_DEVICE_DFS* = 6
  FILE_DEVICE_DISK* = 7
  FILE_DEVICE_DISK_FILE_SYSTEM* = 8
  FILE_DEVICE_NETWORK_FILE_SYSTEM* = 0x14
  FILE_DEVICE_VIRTUAL_DISK* = 0x24

  FILE_DEVICE_NAMED_PIPE* = 0x11

  FILE_DEVICE_CONSOLE* = 0x00000050
  FILE_DEVICE_NULL* = 0x00000015
  FILE_DEVICE_KEYBOARD* = 0x0000000b
  FILE_DEVICE_MODEM* = 0x0000002b
  FILE_DEVICE_MOUSE* = 0x0000000f
  FILE_DEVICE_PARALLEL_PORT* = 0x00000016
  FILE_DEVICE_PRINTER* = 0x00000018
  FILE_DEVICE_SCREEN* = 0x0000001c
  FILE_DEVICE_SERIAL_PORT* = 0x0000001b
  FILE_DEVICE_SOUND* = 0x0000001d

  FILE_ATTRIBUTE_READONLY* = cast[DWORD](1)
  FILE_ATTRIBUTE_DIRECTORY* = cast[DWORD](0x10)

  GENERIC_READ* = cast[DWORD](0x80000000)

  IO_REPARSE_TAG_SYMLINK* = cast[DWORD](0xA000000C)

  FILE_READ_ATTRIBUTES* = 128
  FILE_WRITE_ATTRIBUTES* = 0x100

  FILE_ATTRIBUTE_REPARSE_POINT* = cast[DWORD](0x400)
  IO_REPARSE_TAG_MOUNT_POINT* = cast[DWORD](0xA0000003)

let
  INVALID_FILE_ATTRIBUTES*{.importc, header: "<WinNT.h>".}: DWORD

proc GetFileAttributesW*(lpFileName: LPCWSTR): DWORD {.
    stdcall, header: "<WinNT.h>", importc.}
proc SetFileAttributesW*(lsFileName: LPCWSTR, attr: DWORD): WINBOOL {.
    stdcall, header: "<WinNT.h>", importc.}

proc GetFileType*(h: Handle): DWORD{.importc, header: "<fileapi.h>".}

proc GetFileInformationByHandle*(hfile: Handle,
  lpFileInformation: var BY_HANDLE_FILE_INFORMATION): BOOL {.
    stdcall, header: "<fileapi.h>", importc.}
proc GetFileInformationByHandleEx*(
  hfile: Handle, infoClass: FILE_INFO_BY_HANDLE_CLASS, lpBuffer: pointer, dwBufferSize: DWORD
): BOOL {.importc, header: "<winbase.h>".}

proc GetFileInformationByHandleEx*[T](
  hfile: Handle, infoClass: FILE_INFO_BY_HANDLE_CLASS, lpBuffer: var T
): BOOL = GetFileInformationByHandleEx(
  hfile, infoClass, addr lpBuffer, DWORD sizeof(T)
)

template GetFileBasicInformationByHandleEx*(
  hfile: Handle, lpBuffer: FILE_BASIC_INFO
): BOOL =
  bind GetFileInformationByHandleEx, FILE_INFO_BY_HANDLE_CLASS, DWORD
  GetFileInformationByHandleEx(
    hfile, FILE_INFO_BY_HANDLE_CLASS.FileBasicInfo, addr lpBuffer, DWORD sizeof(FILE_BASIC_INFO)
  )


proc FindFirstFileW*(lpFileName: WideCString,
                    lpFindFileData: var WIN32_FIND_DATAW): Handle {.
    stdcall, dynlib: "kernel32", importc, sideEffect.}

proc GetLastError*(): DWORD {.
    stdcall, header: "<errhandlingapi.h>", importc, sideEffect.}

proc SetLastError*(err: DWORD) {.
    stdcall, header: "<errhandlingapi.h>", importc, sideEffect.}


proc CreateFileW*(
  lpFileName: WideCString, dwDesiredAccess: DWORD, dwShareMode: DWORD,
  lpSecurityAttributes: pointer, dwCreationDisposition: DWORD,
  dwFlagsAndAttributes: DWORD, hTemplateFile: Handle
): Handle {.stdcall, header: "<fileapi.h>", importc.}


proc IsReparseTagNameSurrogate*(tag: DWORD): BOOL {.
    importc, header: "<winnt.h>".}

proc FindClose*(hFindFile: Handle): BOOL{.discardable,
  importc, header: "<fileapi.h>".}
