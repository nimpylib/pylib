

import ./cfg
export whenAuditEnabled

import ./main
export audit
template callAudit(event: static string; vargs: varargs[untyped]): NimNode =
  whenAuditEnabledOr(
    newCall(bindSym"audit", newLit event, vargs), newEmptyNode())

template addaudit*(res: NimNode; event: static string; vargs: varargs[untyped]) =
  bind whenAuditEnabled, callAudit
  whenAuditEnabled:
    res.add callAudit(event, vargs)

template newStmtWithAudit*(event: static string; vargs: varargs[untyped]): NimNode =
  bind whenAuditEnabled, callAudit
  whenAuditEnabledOr(newStmtList callAudit(event, vargs), newStmtList())
