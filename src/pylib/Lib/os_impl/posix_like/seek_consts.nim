
when defined(nimdoc):
  import ../../../version

const
  SEEK_SET* = 0
  SEEK_CUR* = 1
  SEEK_END* = 2

const notSEEK012 = false  #[ Currently I've found none, trace
https://stackoverflow.com/questions/78819022/
will-seek-set-seek-cur-seek-end-not-be-0-1-2-on-any-c-lib/78821517]#
when notSEEK012:
  {.push header: "<stdio.h>".}
  # though lseek's `SEEK_*` is said to be in <unistd.h>
  # it's impossible for them to differ those in <stdin.h>
  let
    SEEK_SET{.importc.}: cint
    SEEK_CUR{.importc.}: cint
    SEEK_END{.importc.}: cint
  {.pop.}
  let ordSEEK =
    SEEK_SET == 0 and
    SEEK_SET == 1 and
    SEEK_END == 2
when notSEEK012:
  proc toCSEEK*(whence: int): cint =
    if ordSEEK: whence.cint
    else:
      case whence
      of 0: SEEK_SET
      of 1: SEEK_CUR
      of 2: SEEK_END
      else:
        # err is handled below;
        # also, SEEK_HOLE, SEEL_DATA may be accepted too
        whence.cint
else:
  template toCSEEK*(whence: int): cint =
    whence.cint


when defined(nimdoc):
  # Currently no way add document comment node to let via macro
  template SEEK_DATA*: int{.pysince(3,3).} =
    ## not defined in Windows
    ##
    ## .. note:: this is in fact a runtime constant,
    ##   defined as template only during document generation process.
    ##   **Cannot** use as `SEEK_DATA()` (with parentheses).
    ##
    ## .. hint:: only usable if `<unistd.h>` in your system defines it,
    ##
    ## .. hint::  only supported on some filesystems,
    ##   refer to your system's manpage of `lseek`
  template SEEK_HOLE*: int{.pysince(3,3).} =
    ## see `SEEK_DATA`_ for hints.
else:
  when not defined(js) and not defined(windows):
    {.emit: """
    /*INCLUDE_SECTION*/
    #define _GNU_SOURCE
    """.}
    {.push header: "<unistd.h>".}
    let
      sdata{.importc: "SEEK_DATA".}: cint
      shole{.importc: "SEEK_HOLE".}: cint
    {.pop.}
    let
      SEEK_DATA* = int sdata
      SEEK_HOLE* = int shole
