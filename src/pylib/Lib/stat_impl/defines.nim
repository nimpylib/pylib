
const
  DW* = defined(windows)
  APPLE* = defined(macosx)
const
  SYS_STAT_H* = "<sys/stat.h>"


when DW:
  const WINNT_H* = "<winnt.h>"
