
import ./bytesimpl

import ../stringlib/percent_format
import ../builtins/asciiImpl

template nimpylib_private_genByteLikePercentFormat*(Bytes){.dirty.} =
  ## export just for bytearray. internal use
  bind genPercentAndExport, pyasciiImpl
  genPercentAndExport Bytes, pyasciiImpl, pyasciiImpl, disallowPercentb=false

nimpylib_private_genByteLikePercentFormat PyBytes

