 
when defined(windows):
  import std/winlean
  import ../private/iph_utils
  proc Py_get_osfhandle_noraise*(fd: int): Handle =
    with_Py_SUPPRESS_IPH:
      result = get_osfhandle FileHandle fd
