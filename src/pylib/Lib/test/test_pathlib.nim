

import ./import_utils
importTestPyLib pathlib

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

when defined(posix):
  test "touch, symlink_to, is_file, is_symlink, unlink":
    def f():
      home = pathlib.Path.home()
      ## XXX: do not use cwd, as there may not support create symlink
      fn1 = pre + "file"
      fn2 = pre + "symlink"
      p1 = home / fn1
      p2 = home / fn2

      assert not p1.is_file()
      assert not p2.is_file()
      p1.touch()
      check(p1.is_file())
      p2.symlink_to(p1)
      check(p2.is_symlink())

      p1.unlink()
      p2.unlink()
      check(not p1.is_file())
      check(not p2.is_symlink())
    f()

