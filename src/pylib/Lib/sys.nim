
import std/os
import std/fenv
when defined(nimPreviewSlimSystem):
  import std/assertions

import ../version as libversion
import ../builtins/list
import ../noneType
import ../pystring/strimpl
export list, strimpl

when not defined(pylibSysNoStdio):
  import ./io
  export io.read, io.readline, io.write, io.fileno, io.isatty

  template wrap(ioe): untyped =
    var ioe* = newNoEncTextIO(
      name = '<' & astToStr(ioe) & '>',
      file = system.ioe, newline=DefNewLine)
  # XXX: NIM-BUG: under Windows, system.stdin.readChar for non-ASCII is buggy,
  # returns a random char for one unicode.
  wrap stdin
  wrap stdout
  wrap stderr
  stdin.mode = "r"
  stdout.mode = "w"
  stderr.mode = "w"

proc exit*(s: PyStr) = quit($s)
func exit*(c: int) = quit(c)
func exit*(x: NoneType) = quit(0)
func exit*[T](obj: T) =
  ## .. warning:: this does not raise SystemExit,
  ## which differs Python's
  exit(str(obj))

type FT = float
const
  float_info* = (
    max: maximumPositiveValue FT,
    max_exp: maxExponent FT,
    max_10_exp: max10Exponent FT,
    min: minimumPositiveValue FT,
    min_exp: minExponent FT,
    min_10_exp: min10Exponent FT,
    dig: digits FT,
    mant_dig: mantissaDigits FT,
    epsilon: epsilon FT,
    radix: fpRadix,
    #rounds: 1
  )  ## float_info.rounds is defined as a `getter`, see `rounds`_

when not defined(nimscript):
  let fiRound = fegetround().int
  template rounds*(fi: typeof(float_info)): int =
    ## not available when nimscript
    bind fiRound
    fiRound
else:
  template rounds*(fi: typeof(float_info)): int =
    {.error: "not available for nimscript/compile-time".}

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

  maxsize* = high(BiggestInt)
  byteorder* = str(if cpuEndian == littleEndian: "little" else: "big")
  copyright* = str "MIT"
  #api_version* = NimVersion

const platform* = str(
  when defined(windows): "win32"  # hostOS is windows 
  elif defined(macosx): "darwin"  # hostOS is macosx
  else: hostOS
)
  ## .. warning:: the value may be more precise than Python's, there is a diff-list:
  ## freebsd, solaris, aix, haiku, netbsd for these OSes,
  ## and standalone for bare system.

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

template executable*: PyStr =
  ## .. note:: when nimscript, this is path of `Nim`;
  ## otherwise, it's the path of current app/exe.
  when defined(nimscript):
    str getCurrentCompilerExe()
  else:
    str getAppFilename()

template getsizeof*(x): int =
  mixin sizeof
  sizeof(x)

template getsizeof*(x; default: int): int =
  ## may be used when `sizeof(x)` is a compile-error
  ## e.g. `func sizeof(x: O): int{.error.}` for `O`
  mixin sizeof
  when compiles(sizeof(x)): sizeof(x)
  else: default

