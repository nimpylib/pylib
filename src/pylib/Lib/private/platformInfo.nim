## used by Lib/os and Lib/platform


template unchkUpperAscii(c: char): char =
  char(uint8(c) xor 0b0010_0000'u8)
func capitalizeAscii1(s: string): string =
  ## like strutils.capitalize, but assert s.len > 1
  let c = s[0]
  if c in 'a'..'z': c.unchkUpperAscii & s.substr(1)
  else: s

const Solaris = defined(solaris)

const `platform.system`* =
  when Solaris: "SunOS"
  else: hostOS.capitalizeAscii1

const `sys.platform`* =
  when defined(windows): "win32"  # hostOS is windows 
  elif defined(macosx): "darwin"  # hostOS is macosx
  elif Solaris:         "sunos5"  # hostOS is solaris
  else: hostOS
  ## .. warning:: the value may be more precise than Python's, there is a diff-list:
  ## freebsd, haiku, netbsd for these OSes,
  ## and standalone for bare system.

