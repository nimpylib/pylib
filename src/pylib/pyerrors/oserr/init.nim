
import ./types
import ./oserror_new

template gen(name, typ, thirdDefVal){.dirty.} =
  proc name*(myerrno: cint, strerr: string,
      filename = thirdDefVal, winerror: cint = 0, filename2 = ""): ref PyOSError =
    OSError_new[types.typ](true, myerrno, strerr, filename, winerror, filename2)

template gen(typ, thirdDefVal){.dirty.} =
  gen(`new typ`, typ, thirdDefVal)
  gen(`typ`, typ, thirdDefVal)

gen PyOSError, ""
gen BlockingIOError, 0
