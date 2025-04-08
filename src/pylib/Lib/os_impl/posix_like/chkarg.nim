
import ../common

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

proc follow_symlinks_specified*(function_name: string, follow_symlinks: bool): bool{.discardable.} =
  if follow_symlinks:
    return
  argument_unavailable_error(function_name, "follow_symlinks")
  return true

template follow_symlinks_specified*(follow_symlinks: bool): untyped =
  bind getProcName
  follow_symlinks_specified(
    getProcName(),
    follow_symlinks)


