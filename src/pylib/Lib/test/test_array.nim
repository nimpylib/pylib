
import ./import_utils
importTestPyLib array

suite "Lib/array":
  #test "init":
  when compiles(array('w', "123")):
    test "py3.13: 'w' Py_UCS4":
      const s = "12为"
      var arr = array('w', s)
      check arr[2] == "为"
      check arr.tounicode() == s
  test "cmp":
    let
      a = array('i', [1,2])
      b = array('i', [1,2])
    check a >= b
    check not (a > b)
