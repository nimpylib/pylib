
import std/enumerate
import ./bytesimpl
import ../noneType

func maketrans*(_: typedesc[PyBytes], frm, to: PyBytes): PyBytes =
  when not defined(release):
    if frm.len != to.len:
      raise newException(ValueError,
        "maketrans arguments must have same length")
  var res = newString(256)
  for i in 0..255:
    res[i] = chr(i)
  
  for i, c in enumerate frm.chars:
    let nc = to.getChar i
    res[c.ord] = nc
  
  result = bytes res

using self: PyBytes

when defined(release):
  template chkTable(_) = discard
else:
  func chkTable(table: PyBytes) =
    if table.len != 256:
      raise newException(ValueError,
        "translation table must be 256 characters long")

func translate*(self, table: PyBytes): PyBytes =
  chkTable table
  var res = newString self.len
  for i, c in enumerate self.chars:
    res[i] = table.getChar ord(c)
  result = bytes res


func translate*(self, table, delete: PyBytes): PyBytes =
  chkTable table
  var res = newStringOfCap self.len
  for c in self.chars:
    if not delete.hasChar c:
      res.add table.getChar ord(c)
  result = bytes res

func translate*(self; table: NoneType, delete: PyBytes): PyBytes =
  var res = newStringOfCap self.len
  for c in self.chars:
    if not delete.hasChar c:
      res.add c
  result = bytes res


