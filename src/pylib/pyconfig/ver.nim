

when defined(android):
  import ./util
  const ANDROID_API* = from_c_int_underlined("__ANDROID_API__", 0)
else:
  const ANDROID_API* = 0
