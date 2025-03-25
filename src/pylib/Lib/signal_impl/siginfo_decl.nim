
import ./pylifecycle

type struct_siginfo* = ref object
  a: SigInfo

template getter(field){.dirty.} =
  proc field*(self: struct_siginfo): auto = self.a.field

getter si_signo
getter si_code
getter si_errno
getter si_pid
getter si_uid
#getter si_addr
getter si_status
getter si_band
#getter si_value

proc fill_siginfo*(si: SigInfo): struct_siginfo = struct_siginfo(a: si)
