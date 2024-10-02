

import ./import_utils
importTestPyLib n_pathlib

const pre = "__nimpylib_test_pathlib_"

test "touch, unlink, is_file":
  def f():
    p = Path(pre+"file")
    assert not p.is_file()
    p.touch()
    check p.is_file()
    p.unlink()
    check not p.is_file()
  f()
