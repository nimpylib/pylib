## When `not defined(release) or defined(pylibSysAudit)`, audit will be enabled.
## Otherwise, it will be disabled.
import ./auditImpl/main
export main
