
import std/winlean except DWORD
export winlean except DWORD
import ./get_osfhandle
export get_osfhandle
type
  DWORD* = uint32
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
