

var errno*{.importc, header: "<errno.h>".}: cint
proc strerror(code: cint): cstring{.importc, header: "<string.h>".}

proc osErrorMsg(errCode: cint): string =
  result = $strerror(errCode)

proc newErrnoErr*(additionalInfo = ""): owned(ref OSError) =
  result = (ref OSError)(errorCode: errno.int32, msg: osErrorMsg(errno))
  if additionalInfo.len > 0:
    if result.msg.len > 0 and result.msg[^1] != '\n': result.msg.add '\n'
    result.msg.add "Additional info: "
    result.msg.add additionalInfo
      # don't add trailing `.` etc, which negatively impacts "jump to file" in IDEs.
  if result.msg == "":
    result.msg = "unknown OS error"

proc raiseErrno*(additionalInfo = "") =
  raise newErrnoErr(additionalInfo)