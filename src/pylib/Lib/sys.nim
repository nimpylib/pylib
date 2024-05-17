

import ../version as libversion
import ../builtins/list
import ../noneType
import ../pystring/strimpl

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

  ## From http://devdocs.io/python~3.7/library/sys
  platform* = str hostOS
  maxsize* = high(BiggestInt)
  byteorder* = str $cpuEndian
  copyright* = str "MIT"
  #api_version* = NimVersion

