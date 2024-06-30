
when NimMajor > 1:
  import std/envvars
else:
  import std/os

import ./force_ascii_utils
import ./localeutils

proc setenvOverwrite*(key, val: string): bool =
  try:
    putEnv(key, val)
    result = true
  except OSError:
    result = false

proc c_getenv*(v: cstring): cstring{.importc: "getenv", header: "<stdlib.h>".}


# Python/pylifecycle.c L319
# _Py_SetLocaleFromEnv
proc Py_SetLocaleFromEnv*(category: cint): cstring{.discardable.} =
  when defined(android):
    var locale: string

    when defined(PY_COERCE_C_LOCALE):
      var coerce_c_locale: cstring

    const utf8_locale = cstring"C.UTF-8"
    let env_var_set = [
      cstring"LC_ALL",
      cstring"LC_CTYPE",
      cstring"LANG",
    ]
    #[Android setlocale(category, "") doesn't check the environment variables
     and incorrectly sets the "C" locale at API 24 and older APIs. We only
     check the environment variables listed in env_var_set. */]#
    
    for evar in env_var_set:
      locale = c_getenv(evar)
      if locale != "":
        if locale == utf8_locale or
          locale == "en_US.UTF-8":
            return c_setlocale(category, utf8_locale)
        return c_setlocale(category, "C")
    #[ Android uses UTF-8, so explicitly set the locale to C.UTF-8 if none of
      LC_ALL, LC_CTYPE, or LANG is set to a non-empty string.
      Quote from POSIX section "8.2 Internationalization Variables":
      "4. If the LANG environment variable is not set or is set to the empty
      string, the implementation-defined default locale shall be used." ]#
    when defined(PY_COERCE_C_LOCALE):
      # FIT(py): we currently do not get affected by Python's env
      #coerce_c_locale = c_getenv("PYTHONCOERCECLOCALE")
      #if coerce_c_locale == nil or coerce_c_locale == "0":
        if not setenvOverwrite("LC_CTYPE", utf8_locale):
          stderr.write "Warning: failed setting the LC_CTYPE " &
                          "environment variable to "&utf8_locale&'\n'
    result = c_setlocale(category, utf8_locale)
  else:
    result = c_setlocale(category, "")
  
  Py_ResetForceASCII()

  