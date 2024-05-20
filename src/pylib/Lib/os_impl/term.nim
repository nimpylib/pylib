
import std/terminal
when defined(nimPreviewSlimSystem):
  import std/syncio

template fileno(f: File): int = int getFileHandle f
template STDOUT_FILENO: int = fileno(stdout)
type terminal_size* = tuple[columns, lines: int]  ## a namedtuple 
                                                  ## instead of a class
proc get_terminal_size*(fd=STDOUT_FILENO): terminal_size =
  ## minics Python's os.get_terminal_size.
  ## 
  ## but if you are using Nim's stdlib,
  ## `terminalSize<https://nim-lang.org/docs/terminal.html#terminalSize>`
  ## in std/terminal does futher than even
  ## Python's `shutil.get_terminal_size`
  # We do not refer to env-vars, as Python's does not.
  result.columns = terminalWidthIoctl([fd])
  result.lines = terminalHeightIoctl([fd])
