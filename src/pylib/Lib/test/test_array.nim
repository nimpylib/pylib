
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
  test "bytes":
    let arr = array('b', b"123")
    check arr.len == 3
    check arr[2] == cschar '3'
    check arr.tobytes() == b"123"
  test "cmp":
    let
      a = array('i', [1,2])
      b = array('i', [1,2])
    check a == b
    check a >= b
    check not (a > b)
    template ccmp[A; A2](c: char, a: A, op; b: A2) =
      check op(array(c, a), array(c, b))
    ccmp 'i', [1, 3], `<`, [1, 4]
    ccmp 'i', [1, 3, 2], `<`, [1, 4]
    ccmp 'i', [1, 3, 2], `>`, [1, 3]
