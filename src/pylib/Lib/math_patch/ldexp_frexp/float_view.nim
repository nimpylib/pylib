
when defined(js):
  import ./jsTypedArray
  export jsTypedArray
  let
    FLOAT64_VIEW* = newFloat64Array(1)
    UINT32_VIEW* = newUint32Array(FLOAT64_VIEW.buffer)
  
    FLOAT32_VIEW* = newFloat32Array(1)
    UINT16_VIEW* = newUint16Array(FLOAT32_VIEW.buffer)

else:
  type
    VIEW64 {.union.}= object
      uint: array[2, uint32]
      float: array[1, float]
    VIEW32 {.union.}= object
      uint: array[2, uint16]
      float: array[1, float32]
  var
    view64: VIEW64
    view32: VIEW32
  template FLOAT64_VIEW*: array =
    bind view64;
    view64.float
  template UINT32_VIEW*: array =
    bind view64
    view64.uint
  template FLOAT32_VIEW*: array=
    bind view32
    view32.float
  template UINT16_VIEW*: array =
    bind view32
    view32.uint

