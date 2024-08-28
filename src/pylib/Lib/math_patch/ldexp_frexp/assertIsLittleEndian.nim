 

when not defined(js):
  proc isLittleEndian*: bool =
    cpuEndian == littleEndian
elif defined(nodejs):
    proc os_endianness(): cstring{.importjs: "require('node:os').endianness()".}
    proc isLittleEndian*: bool =
      os_endianness() == "LE"
else:
  # non-nodejs JS
  {.emit: """
function __inner_isLittleEndian() {
	var uint16view;
	var uint8view;

	uint16view = new Uint16Array( 1 );

	/*
	* Set the uint16 view to a value having distinguishable lower and higher order words.
	*
	* 4660 => 0x1234 => 0x12 0x34 => '00010010 00110100' => (0x12,0x34) == (18,52)
	*/
	uint16view[ 0 ] = 0x1234;

	// Create a uint8 view on top of the uint16 buffer:
	uint8view = new Uint8Array( uint16view.buffer );

	// If little endian, the least significant byte will be first...
	return ( uint8view[ 0 ] === 0x34 );
}""".}
  proc isLittleEndian*: bool {.importjs: "__inner_isLittleEndian()".}
