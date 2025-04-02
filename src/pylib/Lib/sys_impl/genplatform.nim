
# CPython-3.13.0's sys.platform is getten from Python/getplatform.c Py_GetPlatform,
# which returns PLATFORM macro,
# which is defined in Makefile.pre.in L1808 as "$(MACHDEP)"
# and MACHDEP is defined in configure.ac L313

import ./util

when defined(js) and not defined(nodejs):
  from std/strutils import toLowerAscii, startsWith

when defined(linux) or defined(aix):
  import ../private/platformInfo

  template sufBefore(pre: string, ver: (int, int)): string =
    when (PyMajor, PyMinor) < ver:
      pre & uname_release_major()
    else:
      pre

proc getPlatform*(): string =
  when defined(js):
    when defined(nodejs):
      proc `os.platform`(): cstring{.importjs:
        "require('os').platform()".}
      return `os.platform`().`$`
    else:
      let `navigator.platform`{.importjs: "(navigator.platform||process.platform)".}: cstring
      result = `navigator.platform`.`$`.toLowerAscii
      result =
        if result.startsWith "win32": "win32"
        elif result.startsWith "linux": "linux"
        elif result.startsWith "mac": "darwin"
        else: result## XXX: TODO
  else:
    when defined(windows): "win32"  # hostOS is windows
    elif defined(macosx): "darwin"  # hostOS is macosx
    elif defined(android): "android"
    elif defined(linux): "linux".sufBefore (3,3)
    elif defined(aix): "aix".sufBefore (3,8)
    else:
      when defined(solaris):
        # Only solaris (SunOS 5) is supported by Nim, as of Nim 2.1.1,
        # and SunOS's dev team in Oracle had been disbanded years ago
        # Thus SunOS's version would never excceed 5 ...
        "sunos5"  # hostOS is solaris
      elif hostOS == "standalone":
        hostOS
      else:
        # XXX: haiku, netbsd  ok ?
        hostOS & uname_release_major()

template genPlatform*(S){.dirty.} =
  bind getPlatform
  when defined(js):
    let platform* = S getPlatform()
  else:
    const platform* = S getPlatform()
      ## .. note:: the value is standalone for bare system
      ## and haiku/netbsd appended with major version instead of "unknown".
      ## In short, this won't be "unknown" as Python does.
