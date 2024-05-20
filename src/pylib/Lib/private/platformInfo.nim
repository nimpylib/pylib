## used by Lib/os and Lib/platform


template unchkUpperAscii(c: char): char =
  char(uint8(c) xor 0b0010_0000'u8)
func capitalizeAscii1(s: string): string =
  ## like strutils.capitalize, but assert s.len > 1
  let c = s[0]
  if c in 'a'..'z': c.unchkUpperAscii & s.substr(1)
  else: s

const `platform.system`* = hostOS.capitalizeAscii1

const `sys.platform`* =
  when defined(windows): "win32"  # hostOS is windows 
  elif defined(macosx): "darwin"  # hostOS is macosx
  else: hostOS
  ## .. warning:: the value may be more precise than Python's, there is a diff-list:
  ## freebsd, solaris, haiku, netbsd for these OSes,
  ## and standalone for bare system.

