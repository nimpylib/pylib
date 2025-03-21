## Lib/sys
##
## .. hint:: if not defined `pylibConfigIsolated`,
##   this module will call `setlocale(LC_CTYPE, "")`,
##   a.k.a. changing locale to user's configure,
##   just as CPython's initialization.

import std/os
import std/fenv
from ../Python/force_ascii_utils import Py_FORCE_UTF8_FS_ENCODING
when defined(js) and not defined(nodejs) or
    not (Py_FORCE_UTF8_FS_ENCODING or defined(windows)) or
    defined(nimscript):
  import std/strutils # toLowerAscii startsWith
when defined(nimPreviewSlimSystem):
  import std/assertions

import ../version as libversion
import ../builtins/list
import ../noneType
import ../pystring/strimpl

import ../pyconfig/pycore/pymath
const float_repr_style* = str(
  when PY_SHORT_FLOAT_REPR: "short" else: "legacy"
)  ##\
## .. note:: when JS, this is "legacy" but
##   currently `$float` is still of short style.
##   this only affects other function like `round(float, int)`


const weirdTarget = defined(js) or defined(nimscript)
when defined(js):
  import std/jsffi
  when not defined(nodejs): import ../jsutils/deno
when not weirdTarget:
  const inFileSystemUtf8os = defined(macosx) or defined(android) or defined(vxworks)
  when not inFileSystemUtf8os:
    import ../Python/[
      fileutils
    ]
  import ../Python/[
    envutils,
    localeutils  # setlocale, LC_CTYPE
  ]

export list, strimpl

# CPython-3.13.0's sys.platform is getten from Python/getplatform.c Py_GetPlatform,
# which returns PLATFORM macro,
# which is defined in Makefile.pre.in L1808 as "$(MACHDEP)"
# and MACHDEP is defined in configure.ac L313

when defined(linux) or defined(aix):
  import ./private/platformInfo

  template sufBefore(pre: string, ver: (int, int)): string =
    when (PyMajor, PyMinor) < ver:
      pre & uname_release_major()
    else:
      pre

proc getPlatform(): string = 
  when defined(js):
    when defined(nodejs):
      proc `os.platform`(): cstring{.importjs:
        "require('os').platform()".}
      return `os.platform`().`$`
    else:
      let `navigator.platform`{.importjs: "navigator.platform".}: cstring
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

when defined(js):
  let platform* = str getPlatform()
else:
  const platform*: PyStr =
    str getPlatform()
    ## .. note:: the value is standalone for bare system
    ## and haiku/netbsd appended with major version instead of "unknown".
    ## In short, this won't be "unknown" as Python does.

when not weirdTarget:
  when not defined(pylibSysNoStdio):
    # CPython's stdio is init-ed by create_stdio in Python/pylifecycle.c
    import ./io
    export io.read, io.readline, io.write, io.fileno, io.isatty, io.flush

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
    let
      dunder_stdin* = stdin   ## __stdin__
      dunder_stdout* = stdout ## __stdout__
      dunder_stderr* = stderr ## __stderr__
    converter noneStdstream*(n: NoneType): typeof(stdout) = nil

proc exit*(s: PyStr) = quit($s)
func exit*(c: int) = quit(c)
func exit*(x: NoneType) = quit(0)
func exit*[T](obj: T) =
  ## .. warning:: this does not raise SystemExit,
  ##   which differs Python's
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

when not weirdTarget:
  let fiRound = fegetround().int
  template rounds*(fi: typeof(float_info)): int =
    ## not available when nimscript
    bind fiRound
    fiRound
else:
  template rounds*(fi: typeof(float_info)): int =
    {.error: "not available for nimscript/JavaScript/compile-time".}

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
    releaselevel: str $PyReleaseLevel,
    serial: PySerial
  )
  version* = str asVersion((PyMajor, PyMinor, PyPatch))
  hexversion* = version_info.toHexversion

  maxsize* = high(BiggestInt)
  byteorder* = str(if cpuEndian == littleEndian: "little" else: "big")
  copyright* = str "MIT"
  #api_version* = NimVersion

const
  hasArgn = declared(paramCount)
  hasArgs = declared(paramStr)

when hasArgn and hasArgs:
  ## under shared lib in POSIX, paramStr and paramCount are not available

  let
    argn = paramCount()
    argc = argn + 1
  var
    orig_argv* = newPyListOfCap[PyStr](argc)  ##\
      ## .. hint:: rely on
      ##    `paramCount`<https://nim-lang.org/docs/cmdline.html#paramCount>_ and
      ##    `paramStr`<https://nim-lang.org/docs/cmdline.html#paramStr%2Cint>_.
      ##    See their document for availability.
    argv*: PyList[PyStr]

  for i in 0..argn:
    orig_argv.append str paramStr i
  when defined(nimscript):
    if argn > 0:
      argv =
        if orig_argv[1] == "e":
          orig_argv[2..^1]
        else:
          assert orig_argv[1][^5..^1] == ".nims" or
            orig_argv[1].startsWith "-"  # [--opt...] --eval:cmd
          orig_argv[1..^1]
  else: argv = list(orig_argv)

when defined(nimscript):
  template executable*: PyStr = str getCurrentCompilerExe()
elif defined(js):
  when defined(nodejs): 
    let execPath{.importjs: "process.execPath".}: cstring
    template executable*: PyStr =
      bind execPath
      str $execPath
  else:
    func getExecPath: cstring =
      # Deno.execPath() may ask permission,
      #  so we only invoke it when called
      {.noSideEffect.}:
        if inDeno:
          asm "`result` = Deno.execPath()"
        else: result = ""
    template executable*: PyStr =
      bind getExecPath
      str $getExecPath()
else:
  template executable*: PyStr =
    ## returns:
    ##
    ##   - when nimscript, path of `Nim`;
    ##   - when JavaScript:
    ##     - on browser: empty string
    ##     - on NodeJS/Deno: executable path of Node/Deno
    ##   - otherwise, it's the path of current app/exe.
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

const
  Utf8 = "utf-8"
  sUtf8 = str Utf8
proc getdefaultencoding*(): PyStr =
  ## Return the current default encoding used by the Unicode implementation.
  ## 
  ## Always "utf-8" in Nim
  sUtf8

#[ gdb Python3.13.0b2:
watch _PyRuntime->_main_interpreter.config.filesystem_encoding
then we can get a trace:
]#
#[ TODO: after codecs
 Python/pylifecycle.c
  pyinit_main
  Py_InitializeFromConfig
 Object/unicodeobject.c
  _PyUnicode_InitEncodings
  init_fs_encoding
  config_get_codec_name
 Python/codecs.c _PyCodec_Lookup
]#


# ref:
# https://docs.python.org/3/c-api/init_config.html#c.PyConfig.filesystem_encoding
when not weirdTarget and (PyMajor, PyPatch) < (3, 15):
  #[
  Py_PreInitialize
  _Py_PreInitializeFromPyArgv
  [_PyPreConfig_Write] (3.13)
  _Py_SetLocaleFromEnv
  ]#
  # config ref: (PEP 587) and enhence (PEP 741)
  when not defined(pylibConfigIsolated):
    # TODO: consider coerce_c_locale:
    # _PyPreConfig_Read -> preconfig_read -> preconfig_init_coerce_c_locale
    proc simple_Py_PreInitialize =
      Py_SetLocaleFromEnv(LC_CTYPE)
    simple_Py_PreInitialize()

  # source:
  # cpython/Python/initconfig.c
  # config_init_fs_encoding & config_get_fs_encoding
  when inFileSystemUtf8os:
    template getfilesystemencodingImpl(): string = Utf8
  else:
    proc getfilesystemencodingImpl(): string =
      # modified from initconfig.c config_get_fs_encoding
      when Py_FORCE_UTF8_FS_ENCODING:
        return Utf8
      elif defined(windows):
        return
          when false: #0 != preconfig.legacy_windows_fs_encoding:
            ##  Legacy Windows filesystem encoding: mbcs/replace
            "mbcs"
          else:
            ##  Windows defaults to utf-8/surrogatepass (PEP 529)
            Utf8
      else:
        template normEncoding(s: string): string =
          ## XXX: see above, currently it's only for
          ## UTF-8 (got in Debian) -> utf-8
          s.toLowerAscii
        # As currently there is no preconfig, we skip the following line.
        #if(preconfig->utf8_mode)... // use utf-8
        if force_ascii_utils.Py_GetForceASCII():
          return "ascii"
        normEncoding Py_GetLocaleEncoding()
  when (PyMajor, PyMinor) >= (3,7):
    let filesystem_encoding: PyStr = block:
      let loc = c_setlocale(LC_CTYPE, nil)
      if loc != nil and loc == "C" or loc == "POSIX":
        # utf-8 mode (PEP 540)
        sUtf8
      else:
        str getfilesystemencodingImpl()
  else:
    let filesystem_encoding: PyStr = str getfilesystemencodingImpl()
else:
  # utf-8 mode is enabled by default since 3.15 (pep 686).
  const filesystem_encoding = sUtf8

proc getfilesystemencoding*(): PyStr = filesystem_encoding

