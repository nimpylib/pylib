
import ./cfg
when config_should_audit:
  include ./yesImpl
else:
  include ./noImpl
