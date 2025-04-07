
import ./types
import std/strformat

proc `$`*(self: ref PyOSError): string =
  ## String representation of OSError
  template orNone(x: string): string =
    if x.len > 0: x else: "None"
  template orNone(x: int): string = (if x != 0: $x else: "None")

  when defined(windows):
    # If available, winerror has priority over errno
    if self.winerror != 0:
      result = fmt"[WinError {self.winerror}]"
  if result.len == 0:
    result = fmt"[Errno {orNone(self.errno)}]"
  result.add ' '
  result.add orNone(self.filename)
  if self.filename.len > 0:
    result.add ": "
    result.add self.filename
    if self.filename2.len > 0:
      result.add " -> "
      result.add self.filename2
