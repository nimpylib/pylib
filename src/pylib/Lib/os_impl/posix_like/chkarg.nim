
import ../common
import ./pyCfg
importConfig os

template getProcName(): string =
  when declared(getFrame):
    $getFrame().procName
  else: ""

proc getProcName(depth: int): string =
  when not declared(getFrame): return
  else: 
    var frame = getFrame()
    for _ in 0..depth:  # NOTE: this function is in depth 0
      frame = frame.prev
    $frame.procName

proc argument_unavailable_error*(function_name: string, argument_name: string) =
  var msg: string
  if function_name != "":
    msg = function_name & ": "
  msg.add argument_name
  msg.add " unavailable on this platform"
  raise newException(NotImplementedError, msg)

proc argument_unavailable_error*(argument_name: string) =
  argument_unavailable_error(getProcName(1), argument_name)

using follow_symlinks: bool
using dir_fd, fd: int
using path: PathLike|int

using follow_symlinks: bool
using dir_fd, fd: int
type Path = string|int
using path: Path

proc follow_symlinks_specified*(function_name: string, follow_symlinks): bool{.discardable.} =
  if follow_symlinks:
    return
  argument_unavailable_error(function_name, "follow_symlinks")
  return true

template follow_symlinks_specified*(follow_symlinks: bool): untyped =
  bind getProcName
  follow_symlinks_specified(
    getProcName(),
    follow_symlinks)

template valid_follow_symlinks(follow_symlinks: bool): bool = not follow_symlinks
template valid_fd(fd: int): bool = fd > 0
template valid_dir_fd(dir_fd: int): bool =
  bind DEFAULT_DIR_FD
  dir_fd != DEFAULT_DIR_FD
template valid_path[T: Path](path: T): bool = T is_not int  ## only for path_and_dir_fd_invalid, meaning !path->wide && !path->narrow

template gen_invalid(a, b; msg: string){.dirty.} =
  proc `a and b invalid`*(function_name: string, a; b): bool{.discardable.} =
    if `valid a`(a) and `valid b`(b):
      raise newException(ValueError, function_name & ": " & msg)
    return true
  template `a and b invalid`*(a; b): untyped{.dirty.} =
    bind getProcName
    `a and b invalid`(getProcName(), a, b)

template nonTogether(a, b: string): string =
  "cannot use " & a & " and " & b & " together"

template gen_invalid(a, b){.dirty.} =
  gen_invalid(a, b, nonTogether(astToStr(a), astToStr(b)))

gen_invalid path, dir_fd, "can't specify dir_fd without matching path"
gen_invalid dir_fd, fd, "can't specify both dir_fd and fd"
gen_invalid fd, follow_symlinks
gen_invalid dir_fd, follow_symlinks
