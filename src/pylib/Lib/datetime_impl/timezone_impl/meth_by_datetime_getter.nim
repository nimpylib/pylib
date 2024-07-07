
import ./decl
import ../pyerr
import ../datetime_impl/inner_decl
import ../timedelta_impl/decl

method utcoffset*(self: tzinfo; dt: datetime): timedelta{.base.} = notImplErr(tzinfo.utcoffset)
method utcoffset*(self: timezone; _: datetime): timedelta = self.offset

method dst*(self: tzinfo; dt: datetime): timedelta{.base.} = notImplErr(tzinfo.dst)
method dst*(self: timezone; _: datetime): timedelta =
  ## returns nil
  nil

method tzname*(self: tzinfo; dt: datetime): string{.base.} = notImplErr(tzinfo.tzname)
method tzname*(self: timezone; _: datetime): string = $self
