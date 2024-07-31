
import ./import_utils
importTestPyLib tempfile
from std/os import fileExists
test "Lib/tempfile":
  var tname = ""
  const cont = b"content"
  with NamedTemporaryFile() as f:  # open in binary mode by default
    tname = f.name
    f.write(cont)
    f.flush()
    check fileExists f.name
    f.seek(0)
    check f.read() == cont
  check not fileExists tname
