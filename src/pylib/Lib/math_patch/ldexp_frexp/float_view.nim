
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
  type
    VIEW64 {.union.}= object
      uint: array[2, uint32]
      float: array[1, float]
    VIEW32 {.union.}= object
      uint: array[2, uint16]
      float: array[1, float32]

  # fallback for compileTime VM
  {.push compileTime.}
  type
    FView[F: SomeFloat] = distinct F
  func `[]`*[F](fv: FView[F], i: range[0..0]): F = F(fv)
  template set01gen(F, II, I, Ibit){.dirty.} =
    func set0(fv: var FView[F], i: I) =
      let ii = cast[II](fv).clearMasked 0..(Ibit-1)
      ii or i
    func set1(fv: var FView[F], i: I) =
      var ii = II cast[I](cast[II](fv))  # only reserve bit at 0 index
      ii or (i.II shl Ibit)
  set01gen float64, uint64, uint32, 32
  set01gen float32, uint32, uint16, 16

  func `[]=`*(fv: var FView[F], i: range[0..1], val: SomeUnsignedInt) =
    if i == 0: fv.set0 val
    else: fv.set1 val
  var
    fview64{.compileTime.}: FView[float64]
    fview32{.compileTime.}: FView[float32]
  {.pop.}
  template init64FloatView*(FLOAT64_VIEW, UINT32_VIEW) = discard
  template init32FloatView*(FLOAT32_VIEW, UINT16_VIEW) = discard

  var
    view64: VIEW64
    view32: VIEW32
  template FLOAT64_VIEW*: array =
    when nimvm:
      bind fview64
      fview64
    else:
      bind view64;
      view64.float
  template UINT32_VIEW*: array =
    when nimvm:
      bind fview64
      fview64
    else:
      bind view64
      view64.uint

  template FLOAT32_VIEW*: array=
    when nimvm:
      bind fview32
      fview32
    else:
      bind view32
      view32.float
  template UINT16_VIEW*: array =
    when nimvm:
      bind fview32
      fview32
    else:
      bind view32
      view32.uint

