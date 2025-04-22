
import ./types

template PySys_Audit*(event: string, args: varargs[typed]) = discard

template reportNoAudit() =
  {.warning: "audit not enabled, enable via `-d:pylibSysAudit` in release build mode".}

template PySys_AddAuditHook*(hook: HookProc, userData = default Any) = bind reportNoAudit; reportNoAudit
template addaudithook*(hook: HookProc) = bind reportNoAudit; reportNoAudit

template audit*(event: string, args: varargs[typed]) = discard
