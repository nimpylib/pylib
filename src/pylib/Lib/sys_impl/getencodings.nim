

import ./util

template importPython(submod) =
  import ../../Python/submod
template importPython(submod, sym) =
  from ../../Python/submod import sym


importPython force_ascii_utils, Py_FORCE_UTF8_FS_ENCODING
when defined(js) and not defined(nodejs) or
    not (Py_FORCE_UTF8_FS_ENCODING or defined(windows)) or
    defined(nimscript):
  import std/strutils # toLowerAscii startsWith
when defined(nimPreviewSlimSystem):
  import std/assertions

when defined(js):
  import std/jsffi
when not weirdTarget:
  const inFileSystemUtf8os = defined(macosx) or defined(android) or defined(vxworks)
  when not inFileSystemUtf8os:
    importPython(fileutils)
  importPython envutils
  importPython localeutils  # setlocale, LC_CTYPE

const
  Utf8 = "utf-8"
proc getdefaultencoding*(): string =
  ## Return the current default encoding used by the Unicode implementation.
  ## 
  ## Always "utf-8" in Nim
  Utf8

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
    let filesystem_encoding = block:
      let loc = c_setlocale(LC_CTYPE, nil)
      if loc != nil and loc == "C" or loc == "POSIX":
        # utf-8 mode (PEP 540)
        Utf8
      else:
        getfilesystemencodingImpl()
  else:
    let filesystem_encoding: string = getfilesystemencodingImpl()
else:
  # utf-8 mode is enabled by default since 3.15 (pep 686).
  const filesystem_encoding = Utf8

proc getfilesystemencoding*(): string = filesystem_encoding
