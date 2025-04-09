

when defined(macosx):
  import ./util
  import ./builtin_available
  template check_func_runtime*(fn; macos, ios, tvos, watchos = ANY_VER) =
    ## export const HAVE_`fn`_RUNTIME
    const fn_str = astToStr(fn)
    const `HAVE fn RUNTIME`* = from_c_int_expr("HAVE_" & fn_str & "_RUNTIME",
      when HAVE_BUILTIN_AVAILABLE:
        builtin_available_expr(macos, ios, tvos, watchos)
      else:
        fn_str & " != NULL")
else:
  template check_func_runtime*(fn; versionsOfApple: varargs[untyped]) =
    ## export const HAVE_`fn`_RUNTIME
    const `HAVE fn RUNTIME`* = true
