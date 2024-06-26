
when NimMajor == 1:
  import std/[os, hashes]
  type Path* = distinct string
  func `==`*(head, tail: Path): bool =
    head.normalizePath == tail.normalizePath
  func hash*(self: Path): int = int hash($(self).normalizePath)

else:
  import std/paths
  type Path* = distinct paths.Path
  func `==`*(head, tail: Path): bool{.borrow.}
  when NimMinor > 1 or compiles(paths.Path("").hash):
    func hash*(self: Path): int = int hash(paths.Path(self))
  else:
    import std/hashes
    func hash*(self: Path): int =
      var p = paths.Path(self)
      p.normalizePath
      int hash(string p)    


func `/`*(head, tail: Path): Path{.borrow.}

func `$`*(p: Path): string = string p
