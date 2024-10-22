
import std/options
from std/os import fileExists
import ./n_tempfile
export n_tempfile except mktemp, mkdtemp, name, templ, gettempdir, gettempprefix
import ../pystring/strimpl
import ../pybytes/bytesimpl
import ../noneType
import ../version

# TODO: SpooledTemporaryFile

proc mktemp*(suffix="", prefix=templ, dir: PyStr|NoneType = "", checker=fileExists): PyStr =
  when dir is NoneType:
    let dir = ""
  str n_tempfile.mktemp(suffix, prefix, dir, checker)

template name*(self: TemporaryFileWrapper): PyStr =
  bind str, name
  str name self

type SOption = Option[string]
proc mkdtemp*(
    suffix: PyStr|NoneType = None,
    prefix: PyStr|NoneType = None,
    dir:    PyStr|NoneType = None): PyStr =
  converter optstr2nim(o: PyStr|NoneType): SOption =
    when o is NoneType: return none
    else: return some o
  str n_tempfile.mkdtemp(suffix, prefix, dir)

template gen_s2bs(s, b) =
  proc s*(): PyStr =
    str n_tempfile.gettempdir()

  proc b*(): PyBytes{.pysince(3,5).} =
    bytes n_tempfile.gettempdir()


gen_s2bs gettempdir, gettempdirb
gen_s2bs gettempprefix, gettempprefixb
