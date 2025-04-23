
include ./ncommon
import ../common

# translated from CPython-3.13-alpha/Modules/posixmodule.c L5674
# internal_rename
when defined(windows):
  proc internal_rename[T](src, dst: PathLike[T], is_replace: static[bool]): bool =
    let flag = when is_replace: MOVEFILE_REPLACE_EXISTING else: 0
    let s = newWideCString($src)
    let d = newWideCString($dst)
    result = moveFileExW(s, d, flag.DWORD) != 0'i32
else:
  proc c_rename(src, dst: cstring): cint{.importc: "rename", header: "<stdio.h>".}
  proc internal_rename[T](src, dst: PathLike[T], is_replace: static[bool]): bool =
    result = c_rename(cstring $src, cstring $dst) == 0.cint

proc rename*[T](src, dst: PathLike[T]) =
  sys.audit("os.rename", src, dst, -1, -1)
  if not internal_rename(src, dst, false):
    raiseExcWithPath2(src, dst)

proc replace*[T](src, dst: PathLike[T]) = 
  if not internal_rename(src, dst, true):
    raiseExcWithPath2(src, dst)
