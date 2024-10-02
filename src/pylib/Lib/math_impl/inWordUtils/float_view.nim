## for JS and C-like backends
##
## Not for nimvm, see {to,from}Words for impl for nimvm backend

when defined(js):
  import ./jsTypedArray
  export jsTypedArray
      
  template init64FloatView*(FLOAT64_VIEW, UINT32_VIEW) =
    let
      FLOAT64_VIEW = newFloat64Array(1)
      UINT32_VIEW = newUint32Array(FLOAT64_VIEW.buffer)
    
  template init32FloatView*(FLOAT32_VIEW, UINT16_VIEW) =
    let
      FLOAT32_VIEW = newFloat32Array(1)
      UINT16_VIEW = newUint16Array(FLOAT32_VIEW.buffer)

else:
  #  this section is for C-like's Nim impl, as union objects are only implemented for them
  #
  # However, maybe ./{to,from}Words's implementation is at least more effecient than this?
  # (or at least much simpler)
  # TODO: check it
  type
    VIEW64 {.union.}= object
      uint*: array[2, uint32]
      float: float
    VIEW32 {.union.}= object
      uint*: array[2, uint16]
      float: float32

  template genSlice(FView, F, II, I){.dirty.} =
    func `[]`*(fv: FView, _: range[0..0]): F = fv.float
    func `[]=`*(fv: var FView, _: range[0..0], f: F) = fv.float = f

  genSlice VIEW64, float64, uint64, uint32
  genSlice VIEW32, float32, uint32, uint16


  template init64FloatView*(FLOAT64_VIEW, UINT32_VIEW) =
    bind VIEW64
    var FLOAT64_VIEW: VIEW64
    template UINT32_VIEW: untyped = FLOAT64_VIEW.uint
  template init32FloatView*(FLOAT32_VIEW, UINT16_VIEW) =
    bind VIEW32
    var FLOAT32_VIEW: VIEW32
    template UINT16_VIEW: untyped = FLOAT32_VIEW.uint
