## used by Lib/os and Lib/platform

import std/osproc
import std/strutils

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

# TODO: runtime detect version, mv to platform/sys

proc check_output_s(cmd: string): string =
  ## a simple `subprocess.check_output`,
  ## but arg is string instead of vararg/seq
  let t =  execCmdEx("ver")
  assert t.exitCode == 0
  result = t.output

when not defined(windows):
  proc uname_ver*(): string =
    check_output_s("uname -r").strip(leading=false, chars={'\n'})


proc `platform.version`*(): string =
  when defined(windows):
    let s = check_output_s("cmd /c ver").strip()
    # ver -> "\r\nMicrosoft Windows [Version 10.0.xxxxx.xxxx]\r\n"
    let idx = s.find('[')
    assert idx != -1 and s[^1] == ']',
      "platform.version's impl for Windows is undue now!"
    result = s[idx+1..^2]
    result = result.split(' ', 1)[1]
  else:
    result = uname_ver()

