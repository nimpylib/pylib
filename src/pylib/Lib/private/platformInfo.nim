## used by Lib/os and Lib/platform

const weirdTarget = defined(nimscript) or defined(js)
when not weirdTarget:
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



proc check_output_s(cmd: string): string =
  ## a simple `subprocess.check_output`,
  ## but arg is string instead of vararg/seq
  let t = when weirdTarget: gorgeEx(cmd) else: execCmdEx(cmd)
  assert t.exitCode == 0
  result = t.output

when not defined(windows):
  func without(s: string, chars: set[char]): string =
    for c in s:
      if c not_in chars:
        result.add c

  # translated from CPython/configure when setting `ac_md_release`
  proc ac_md_release*(): string =
    result = check_output_s(
      when defined(aix) or defined(UnixWare) or defined(OpenUNIX): "uname -v"
      # though UnixWare, OpenUNIX are not officially supported by Nim currently.
      else: "uname -r"
    )
    result.removeSuffix '\n'

    # tr -d '/ '
    result = result.without {'/', ' '}

    # sed 's/^[A-Z]\.//'
    result.removeSuffix {'A'..'Z'}
    result.removePrefix '.'

  proc uname_release_major*(): string =
    ac_md_release().split('.', 1)[0]  # sed 's/\..*//'`


proc `platform.version`*(): string =
  when defined(windows):
    # ver -> "\r\nMicrosoft Windows [Version x.x.xxxxx.xxxx]\r\n"
    let s = check_output_s("cmd /c ver").strip(chars={'\r', '\n'})
    let idx = s.find('[')
    assert idx != -1 and s[^1] == ']',
      "platform.version's impl for Windows is undue now!"
    result = s[idx+1..^2]
    result = result.split(' ', 1)[1]
  else:
    result = ac_md_release()
    # XXX: TODO: maybe not suitable, see CPython's Lib/platform

