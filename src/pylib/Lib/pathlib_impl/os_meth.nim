## rely pylib/Lib/nos

import ../os_impl/touch as touchLib
import ../os_impl/posix_like/unlink as unlinkLib
import ../os_impl/posix_like/stat as statLib
import ./types

using self: Path

proc touch*(self; mode=0o666, exist_ok=true) =
  ## Create this file with the given access mode, if it doesn't exist.    
  touchLib.touch($self, mode, exist_ok)

proc unlink*(self) =
  ## for missing_ok==False
  unlinkLib.unlink $self

proc stat*(self): stat_result = statLib.stat($self)