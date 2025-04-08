
when NimMajor > 1:
  from std/oserrors import OSErrorCode
else:
  from std/os import OSErrorCode

const
  InNodeJs* = defined(nodejs)

import ../jsutils/consts

const DEF_INT = low(int)
let
  ErrExist* = from_js_const(EEXIST, DEF_INT)
  ErrNoent* = from_js_const(ENOENT, DEF_INT)
  ErrIsdir* = from_js_const(EISDIR, DEF_INT)

proc jsErrnoMsg*(errorCode: OSErrorCode): string =
  let ie = errorCode.int
  if ie == ErrExist: "File exists"
  elif ie == ErrNoent: "No such file or directory"
  elif ie == ErrIsdir: "Is a directory"
  else: "<unmapped error msg yet>"


template catchJsErrAsCode*(doBody: static string): int =
  var
    res: cint = 0
  {.emit: ["try{", doBody, "} catch(e) {",
      res, " = -e.errno; }"
  #" <- for code lint
  ].}
  int -res # nodejs's errno is oppsite?

template catchJsErrAsCode*(prc: proc ()): cint =
  var res: cint = 0
  block:
    {.emit: ["try{", prc, "();",
    "} catch(e) {",
        res, """= -e.errno;
    }
    """].}
    #"""] <- for code lint
    res

template catchJsErrAsCode*(doBody): cint =
  bind catchJsErrAsCode
  proc temp{.genSym.} = doBody
  catchJsErrAsCode(prc=temp)

template catchJsErrAsCode*(errMsg: var string; doBody: static string): cint =
  var
    jsRes: cstring
    res: cint = 0
  {.emit: ["try{", doBody, """
  } catch(e) {
  """, res,  "= -e.errno;",
       jsRes,"""= e.message;
  }
  """].}
  #"""] <- for code lint
  if res != 0: errMsg = $jsRes
  res

template catchJsErrAsCode*(errMsg: var string; prc: proc): cint =
  var
    jsRes: cstring
    res: cint = 0
  block:
    {.emit: ["try{", prc, """();
    } catch(e) {
    """,res, " = -e.errno;",
        jsRes,"""= e.message;
    }
    """].}
    #"""] <- for code lint
    if res != 0: errMsg = $jsRes
    res

template catchJsErrAsCode*(errMsg: var string; doBody): cint =
  proc temp = doBody
  catchJsErrAsCode errMsg, prc=temp
