

import ../../version as libversion

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
  res = (res shl 8) or v[1].int2hex
  res = (res shl 8) or v[2].int2hex
  res = (res shl 4) or (PyReleaseLevel.int and 0xf)
  (res shl 4) or (PySerial and 0xf)

const
  ## we maps import as Nim's,
  ## we ourselves do not have cache on `import`
  
  ## Version information (SemVer).

template genInfos*(S; cache_tag_val){.dirty.} =
  bind PyMajor, PyMinor, PyPatch, PyReleaseLevel, PySerial,
    Major, Minor, Patch, ReleaseLevel, Serial,
    asVersion, toHexversion
  const
    version_info* = (
      major: PyMajor,
      minor: PyMinor,
      patch: PyPatch,
      releaselevel: S $PyReleaseLevel,
      serial: PySerial
    )
    implVersion = (
        major: Major,
        minor: Minor,
        micro: Patch,
        releaselevel: S ReleaseLevel,
        serial: Serial
    )
    implementation* = (
      name: S "pynim",
      version: implVersion,
      hexversion: toHexversion(version_info),
      cache_tag: cache_tag_val
    )
    version* = S asVersion((PyMajor, PyMinor, PyPatch))
    hexversion* = toHexversion(version_info)

    maxsize* = high(BiggestInt)
    byteorder* = S(if cpuEndian == littleEndian: "little" else: "big")
    copyright* = S "MIT"
    #api_version* = NimVersion
