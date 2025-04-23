

const config_should_audit* =
  not defined(nimdoc) and  # NIM-BUG: see ./yesImpl
    not defined(release) or defined(pylibSysAudit)

template whenAuditEnabled*(body) =
  bind config_should_audit
  when config_should_audit:
    body

template whenAuditEnabledOr*[T](exp, elseExp: T): T =
  bind config_should_audit
  when config_should_audit:
    exp
  else:
    elseExp
