
import std/terminal

# Nim consider it's the same as os.terminal_size,
# as they are both tuple of Nim
type terminal_size = tuple[columns, lines: int]
func get_terminal_size*(fallback=(80, 24)): terminal_size =
  ## .. hint:: this does not simply refer to environment variable,
  ## call `os.get_terminal_size`. This is a wrapper around
  ## `terminalSize` of `std/terminal`, which is more steady,
  ## returning meaningful result even when stdout is not associatd with
  ## a terminal.
  result.columns = terminalWidth()
  if result.columns == 0:
    result.columns = fallback[0]
  result.lines = terminalHeight()
  if result.lines == 0:
    result.lines = fallback[1]

