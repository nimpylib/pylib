

import ./ct
when ignore_environment == 0:
  #const use_environment = true
  import std/macros
  import ../../../Python/config_read_env
  var call{.compileTime.} = newCall("redefineFlags")
  proc envImpl(name, fn, envName: NimNode): NimNode =
    call.add nnkExprEqExpr.newTree(name,
      newCall(fn,
        envName,
        name)
    )
    result = newEmptyNode()
  
  macro env(fn; name) = envImpl(name, fn, newCall("toPyEnv", newLit name.strVal))
  macro env(fn; name; envName) = envImpl(name, fn, envName)
  template envE(name) = env ib_e , name
  template envI(name) = env ib_i, name
  template envB(name) = env ib_b, name

  # Python/initconfig.c:config_read_env_vars
  envI debug
  envI verbose
  envI optimize
  envI inspect

  envB dont_write_bytecode
  envB no_user_site

  envE safe_path

  # Python/initconfig.c:config_read_complex_options ->
  # Python/initconfig.c:config_init_int_max_str_digits  
  envI int_max_str_digits

  # Python/preconfig.c:preconfig_init_utf8_mode
  env ib_i, utf8_mode, "PYTHONUTF8"  # XXX: PY-DIFF: python will crash if PYTHONUTF8 is neither 0 nor 1

  # Python/preconfig.c:_PyPreCmdline_Read
  envE dev_mode
  #[
  XXX: PY-BUG: as of v3.14.0a7, https://docs.python.org/3/library/devmode.html#devmode says 
  "setting the PYTHONDEVMODE environment variable to 1."
  but it's just implemented as checking existence of PYTHONDEVMODE, whatever it's set: 0, -1 ,etc
  ]#
  envE warn_default_encoding

  macro genCall = call
  genCall()

#[
const PY_LONG_DEFAULT_MAX_STR_DIGITS = 
 len $high(int)
 ## 4300  ## PY-DIFF: no use (PyLong is not implemented)
]#
