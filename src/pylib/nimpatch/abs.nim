{.used.}
import ./utils
addPatch((2,1,1), defined(js) and compileOption("jsBigInt64")):
  func abs*[T: SomeSignedInt](x: T): T{.inline.} =
    ## For JS,
    ## Between nim's using BigInt and 
    ## this [patch](https://github.com/nim-lang/Nim/issues/23378)
    ##   `system.abs` will gen: `(-1)*x`, which can lead to a runtime err
    ## as `x` may be a `bigint`, which causes error:
    ##    Uncaught TypeError: Cannot mix BigInt and other types, ...
    if x < 0.T: result = T(-1) * x
    else: result = x
