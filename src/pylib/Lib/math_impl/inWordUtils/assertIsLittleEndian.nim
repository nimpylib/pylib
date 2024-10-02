 
const compileLittleEndian* = cpuEndian == littleEndian

template wrapVM(body): bool =
  when nimvm: compileLittleEndian
  else: body

when not defined(js):
  func isLittleEndian*: bool{.compileTime.} = compileLittleEndian
    
elif defined(nodejs):
    when defined(es6):
      let jsLittleEndianExpr{.importjs: "(await import('node:os')).endianness() == 'LE'".}: bool
      let jsLittleEndian = jsLittleEndianExpr  # force no inline in case `await` appears in function
      func isLittleEndian*: bool =
        wrapVM:
          {.noSideEffect.}:
            result = jsLittleEndian
    else:
      proc os_endianness(): cstring{.importjs: "require('node:os').endianness()".}
      func isLittleEndian*: bool =
        wrapVM os_endianness() == "LE"
else:
  import ./jsTypedArray
  func isLittleEndian*: bool =
    wrapVM:
      # 4660 => 0x1234 => 0x12 0x34 => '00010010 00110100' => (0x12,0x34) == (18,52)
      var uint16view = newUint16Array(1)
      uint16view[0] = 0x1234
      var uint8view = newUint8Array(uint16view.buffer)
      # If little endian, the least significant byte will be first...
      uint8view[0] == 0x34

