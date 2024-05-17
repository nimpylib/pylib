
when NimMajor > 1:
  import std/cmdline
else:
  import std/os

when defined(nimPreviewSlimSystem):
  import std/assertions

import ../version as libversion
import ../builtins/list
import ../noneType
import ../pystring/strimpl
export list, strimpl

func int2hex(x: int): int =
  ## 10 -> 0x10
  ## and assert 0 <= x < 100
  if x < 10: return x
  let
    hi = x div 10
    lo = x mod 10
  hi shl 4 + lo  # hi * 16 + lo
  
template toHexversion(versionInfo: tuple): int =
  let v = versionInfo
  var res = v[0].int2hex
  res = res shl 8 + v[1].int2hex
  res = res shl 8 + v[2].int2hex
  res

const
  implVersion = (
      major: Major,
      minor: Minor,
      micro: Patch,
      releaselevel: str ReleaseLevel,
      serial: Serial
  )
  implementation* = (
    name: str "pynim",
    version: implVersion,
    hexversion: implVersion.toHexversion,
    cache_tag: None
  )
  ## we maps import as Nim's,
  ## we ourselves do not have cache on `import`
  
  ## Version information (SemVer).
  version_info* = (
    major: PyMajor,
    minor: PyMinor,
    patch: PyPatch,
    releaselevel: PyReleaseLevel,
    serial: PySerial
  )
  version* = str asVersion(version_info)
  hexversion* = version_info.toHexversion

  platform* = str hostOS
  maxsize* = high(BiggestInt)
  byteorder* = str(if cpuEndian == littleEndian: "little" else: "big")
  copyright* = str "MIT"
  #api_version* = NimVersion

let
  argn = paramCount()
  argc = argn + 1
var
  orig_argv* = newPyListOfCap[PyStr](argc)
  argv*: PyList[PyStr]

when not declared(paramStr):
  ## under shared lib in POSIX, paramStr is not available
  argv = newPyList[PyStr]()
else:
  for i in 0..argn:
    orig_argv.append str paramStr i
  argv = when defined(nimscript):
    if argn > 0:
      if orig_argv[1] == "e":
        orig_argv[2..^1]
      else:
        assert orig_argv[1][^5..^1] == ".nims"
        orig_argv[1..^1]
  else: list(orig_argv)
