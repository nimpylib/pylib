
import std/options
from std/os import fileExists
import ./n_tempfile
export n_tempfile except mktemp, mkdtemp, name, templ
import ../pystring/strimpl
import ../pybytes/bytesimpl
import ../noneType
import ../version

proc mktemp*(suffix="", prefix=templ, dir: PyStr|NoneType = "", checker=fileExists): PyStr =
  when dir is NoneType:
    let dir = ""
  str n_tempfile.mktemp(suffix, prefix, dir, checker)

template name*(self: TemporaryFileWrapper): PyStr =
  bind str, name
  str name self

type SOption = Option[string]
proc mkdtemp*(suffix, prefix, dir: PyStr|NoneType = None): PyStr =
  converter optstr2nim(o: PyStr|NoneType): SOption =
    when o is NoneType: return none
    else: return some o
  str n_tempfile.mkdtemp(suffix, prefix, dir)
  