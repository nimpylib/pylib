

const config_should_audit =
  not defined(release) or defined(pylibSysAudit)

when config_should_audit:
  include ./yesImpl
else:
  include ./noImpl
