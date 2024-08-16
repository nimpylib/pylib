
import std/os
when defined(js):
  import ../common
  proc getpid*(): int{.importDenoOrProcess pid.}
else:
  proc getpid*(): int =
    getCurrentProcessId()
