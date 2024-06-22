
import std/macros
import std/strutils
import std/os

proc nimpylibLibFilter*(t: tuple[kind: PathComponent, path: string]): bool =
  t.kind != pcDir and t.kind != pcLinkToDir and
    t.path != "index.nim" and
    not t.path.endsWith"_impl" and
    not t.path.startsWith"n_"

type PathFilter* = typeof nimpylibLibFilter  ## path is relative

proc indexAsMdStr*(dir: string, filter=nimpylibLibFilter): string =
  for t in dir.walkDir(relative=true):
    if filter(t):
      let
        fn = t.path
        libn = fn.changeFileExt("")
        url = fn.changeFileExt("html")
      result.add "- [$#]($#)\n".format(libn, url)


macro genIndexHere*(filter: static[PathFilter] = nimpylibLibFilter) =
  newCommentStmtNode indexAsMdStr(getProjectPath(), filter)
