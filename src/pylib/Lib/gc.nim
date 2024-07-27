## Lib/gc
##
## ## Nim's Memory Management
## 
## Since Nim 2.0, ORC becomes the default mm (memory management).
## In ORC, only a cycle collector will runs at runtime,
## so `enable`_ and `disable`_ only affect this cycle collector,
## a.k.a. `collect` for objects that not causes cycle cannot be
## disabled in runtime, as it's determined at compile-time, namely by ARC.
## 
## Document for Nim's [mm](https://nim-lang.org/docs/mm.html).
##
## Python's gc is similar with
## Nim's [`refc`](https://nim-lang.org/docs/refc.html) mm,
## which is default for Nim 1.x
##
## As Nim's mm is so different from Python's gc,
## only a few APIs of `gc` can be ported to Nim.

proc enable*() =
  when defined(gcOrc): GC_enableOrc()
  else: GC_enable()
proc disable*() =
  when defined(gcOrc): GC_disableOrc()
  else: GC_disable()

const GcCollectResult* = 0  ## Result of `collect`_

proc collect*(): int{.discardable.} =
  ## .. hint:: Do not use the result.
  ##   As there is no way to get
  ##   the number of `gc`-ed objects
  ##   current implement always returns `GcCollectResult`_
  GC_fullCollect()
  GcCollectResult
