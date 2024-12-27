
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
  test "byteswap":
    const
      One = 0x01
      Two = 0x10
    template safeShl[R](x, n): untyped = (when n == 0: x.R else: x.R shl n)
  
    template testType(Typ) =
      const
        TypeSize = sizeof(Typ)
        Shift = 8 * (TypeSize - 1)

      var arr = newPyArray[Typ]()
      arr.append Typ One
      arr.append Typ Two
    
      arr.byteswap()
      check arr[0] == One.safeShl[:Typ](Shift)
      check arr[1] == Two.safeShl[:Typ](Shift)
    
  
    testType  cshort
    testType cushort
  
    testType  cint
    testType cuint

    #testType  clong
    #testType culong
    #[ XXX: NIM-BUG:
~/.cache/nim/test_array_d/@m..@s..@sbuiltins@slist_decl.nim.c:1394:15: error: incompatible types when assigning to type ‘tySequence__lBgZ7a89beZGYPl8PiANMTA’ from type ‘tySequence__UlOHMDjVW8svdcOWlYMPHA’
 1394 | (*T1_).data = colontmpD_;
      |               ^~~~~~~~~~

T1_ is of seq[int]  (colontmpD_ is of seq[clong])
Why?
    
    ]#
