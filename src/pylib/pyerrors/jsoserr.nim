
when NimMajor > 1:
  from std/oserrors import OSErrorCode
else:
  from std/os import OSErrorCode

const
  InNodeJs* = defined(nodejs)
import std/jsffi
when InNodeJs:
  let econsts = require("constants")
else:
  let econsts{.importjs: """(await import("node:constants")).errno""".}: JsObject

let
  ErrExist* = econsts.EEXIST.to(cdouble).int
  ErrNoent* = econsts.ENOENT.to(cdouble).int
  ErrIsdir* = econsts.EISDIR.to(cdouble).int
proc isNotFound*(err: OSErrorCode): bool = err.int == ErrNoent

let jsOs = require("os")


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
      res, " = e.code; }"
  #" <- for code lint
  ].}
  int -res # nodejs's errno is oppsite?

template catchJsErrAsCode*(prc: proc ()): cint =
  var res: cint = 0
  block:
    {.emit: ["try{", prc, "();",
    "} catch(e) {",
        res, """= e.code;
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
  """, res,  "= e.code;",
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
    """,res, " = e.code;",
        jsRes,"""= e.message;
    }
    """].}
    #"""] <- for code lint
    if res != 0: errMsg = $jsRes
    res

template catchJsErrAsCode*(errMsg: var string; doBody): cint =
  proc temp = doBody
  catchJsErrAsCode errMsg, prc=temp
