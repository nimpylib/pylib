
import std/tables
import std/macros

func addDocOfImpl(docFileName: string): NimNode =
  newCommentStmtNode(
      docFileName
  )

func addDocOfImpl(docFileName: string; def: NimNode): NimNode =
  result = def
  result.body.insert(0, addDocOfImpl docFileName)

type
  DocTable* = object
    module: string
    api: Table[string, string]

func initDocTable*(moduleDoc: string, init: openArray[(string, string)]): DocTable{.compileTime.} =
  ## .. hint:: key `""` stands for the module level doc.
  ## 
  DocTable(
    module: moduleDoc,
    api: init.toTable
  )

macro fetchDoc*(tab: static DocTable) =
  ## used for fetch module level doc
  let doc = tab.module
  result = addDocOfImpl doc

macro fetchDoc*(tab: static DocTable; def) =
  ## used as proc's pragma to fetch doc
  let funcName = def.name.strVal
  let fn = tab.api.getOrDefault funcName
  if fn.len == 0:
    return def
  result = addDocOfImpl(fn, def)
