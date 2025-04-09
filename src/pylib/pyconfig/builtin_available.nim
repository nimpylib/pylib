
when defined(macosx):
  import ./util
  const
    HAVE_BUILTIN_AVAILABLE_int = from_c_int(HAVE_BUILTIN_AVAILABLE, 0):
      {.emit:  """
  #if defined(__has_builtin)
  #if __has_builtin(__builtin_available)
  #define HAVE_BUILTIN_AVAILABLE 1
  #endif
  #endif
    """.}
    HAVE_BUILTIN_AVAILABLE* = HAVE_BUILTIN_AVAILABLE_int != 0
  when HAVE_BUILTIN_AVAILABLE:
    const ANY_VER* = 0.0
    template add_target_version(res, os, ver) =
      when ver != ANY_VER:
        res.add os
        res.add ' '
        res.add $ver
        res.add ','

    func builtin_available_expr(macos, ios, tvos, watchos = ANY_VER): string =
      result = "__builtin_available("
      add_target_version(result, "macOS", macos)
      add_target_version(result, "iOS", ios)
      add_target_version(result, "tvOS", tvos)
      add_target_version(result, "watchOS", watchos)
      result.add "*)"

    template builtin_available*(macos, ios, tvos, watchos = ANY_VER): bool =
      bind from_c_int_expr, builtin_available_expr
      from_c_int_expr(builtin_available_expr(macos, ios, tvos, watchos), 0) != 0


