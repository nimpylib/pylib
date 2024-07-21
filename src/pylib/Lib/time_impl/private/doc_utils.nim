
import std/tables
type
  DocTable* = object
    module: string
    api: Table[string, string]

when defined(nimdoc):
  import std/macros

  func initDocTable*(moduleDoc: string, init: openArray[(string, string)]): DocTable{.compileTime.} =
    ## .. hint:: key `""` stands for the module level doc.
    ## 
    DocTable(
      module: moduleDoc,
      api: init.toTable
    )


  func addDocImpl(doc: string; def: NimNode): NimNode =
    result = def
    result.body.insert(0, newCommentStmtNode doc)
  macro fetchDoc*(tab: static DocTable) =
    ## used for fetch module level doc
    let doc = tab.module
    result = addDocImpl doc

  macro fetchDoc*(tab: static DocTable; def) =
    ## used as proc's pragma to fetch doc
    let funcName = def.name.strVal
    let fn = tab.api.getOrDefault funcName
    if fn.len == 0:
      return def
    result = addDocImpl(fn, def)
else:
  func initDocTable*(moduleDoc: string, init: openArray[(string, string)]): DocTable{.compileTime.} =
    discard
  template fetchDoc*(_: static DocTable) = discard
  template fetchDoc*(_: static DocTable; def) = def
