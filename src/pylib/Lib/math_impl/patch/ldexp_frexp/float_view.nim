
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
  #[  this section shall be for non-vm's Nim impl
      but in current implementation framework, this cannot be used due to `when nimvm`'s limit
  type
    VIEW64 {.union.}= object
      uint: array[2, uint32]
      float: array[1, float]
    VIEW32 {.union.}= object
      uint: array[2, uint16]
      float: array[1, float32]
  ]#

  # fallback for compileTime VM

  import std/bitops
  type
    FView[F: SomeFloat] = distinct F
    IView[I: SomeUnsignedInt, F: SomeFloat] = ptr FView[F]  ## I is the same size as F
  template initIView(fv: FView[float64]): IView[uint64, float64] = addr fv
  template initIView(fv: FView[float32]): IView[uint32, float32] = addr fv

  template inUInt[I, F](self: IView[I, F]): I = cast[I](self[])
  template `inUInt=`[I, F](self: IView[I, F], i: I) = self[] = FView[F] cast[F](i)

  func `[]`*[F](fv: FView[F], i: range[0..0]): F = F(fv)
  func `[]=`*[F](fv: var FView[F], i: range[0..0], f: F) = fv = FView[F](f)

  template gset01gen(F, II, I, Ibit){.dirty.} =
    func set0(fv: var IView[II, F], i: I) =
      let ii = fv.inUInt.clearMasked 0..<Ibit
      let res = ii or i.II
      fv.inUInt = res
    func set1(fv: var IView[II, F], i: I) =
      var ii = II cast[I](fv.inUInt)  # only reserve bit at 0 index
      let res = ii or (i.II shl Ibit)
      fv.inUInt = res
    func `[]=`*(fv: var IView[II ,F], i: range[0..1], val: I) =
      if i == 0: fv.set0 val
      else:      fv.set1 val

    func get0(fv: IView[II, F]): I =
      cast[I](fv.inUInt)
    func get1(fv: IView[II, F]): I =
      cast[I]( fv.inUInt.bitSliced Ibit..<(Ibit*2) )
    func `[]`*(fv: IView[II, F], i: range[0..1]): I =
      if i == 0: fv.get0
      else:      fv.get1

  gset01gen float64, uint64, uint32, 32
  gset01gen float32, uint32, uint16, 16



  template init64FloatView*(FLOAT64_VIEW, UINT32_VIEW) =
    bind initIView
    var
      FLOAT64_VIEW: FView[float64]
      UINT32_VIEW = initIView FLOAT64_VIEW
  template init32FloatView*(FLOAT32_VIEW, UINT16_VIEW) =
    bind initIView
    var
      FLOAT32_VIEW: FView[float32]
      UINT16_VIEW = initIView FLOAT32_VIEW

