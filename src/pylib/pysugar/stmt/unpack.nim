# From https://github.com/Yardanico/nim-snippets/blob/master/unpack_macro.nim
import std/macros

func genSymFrom(data: NimNode, res: var NimNode): bool =
  # we don't need to make a copy of the value if it's already a symbol
  if data.kind != nnkSym:
    # create a new variable
    res = genSym(nskLet, "data")
    return true
  
proc unpackWithLenImpl*(data: NimNode, len2unpack: Positive): NimNode =
  result = nnkStmtList.newTree()
  var sym: NimNode
  var nameIdent: NimNode
  if genSymFrom(data, sym):
    nameIdent = sym
    result.add quote do:
      let `sym` = `data`
  else:
    nameIdent = data

  var res = newNimNode nnkPar
  for ind in 0 ..< len2unpack:
    res.add quote do:
      `nameIdent`[`ind`]

  result.add res

template unpackImplRec*(data: NimNode, symbols: NimNode, res: var NimNode, 
    receiver #[: proc (sym, val: NimNode)]#){.dirty.} =
  ## `res` shall be an nnkStmtList,
  ## will pass all sym and relative val to `recevier`
  bind genSymFrom
  var sym: NimNode
  var nameIdent: NimNode
  if genSymFrom(data, sym):
    nameIdent = sym
    res.add quote do:
      let `nameIdent` = `data`
  else:
    nameIdent = data
  var valIdx = 0 # current data index, needed for handling *
  var backwards = false # we need to use ^ after we find an *
  for i, sym in symbols:
    # _ usually means "we don't want that value"
    if sym.eqIdent "_":
      discard  #  do not `continue`
    # Python-like * in tuple unpacking
    elif sym.kind == nnkPrefix and sym[0].eqIdent "*":
      let valName = sym[1]
      # handle *_ (yes it's valid in Python too)
      let needGenerate = not valName.eqIdent"_"
      # get how much variables we have till the end (+1)
      let ends = symbols.len - i
      # starting from the next value we'll do backwards indexing
      backwards = true
      # let `valName` = `nameIdent`[`valIdx` .. ^`ends`]
      if needGenerate:
        receiver(
          valName,
          nnkBracketExpr.newTree(
            nameIdent,
            infix(
              newIntLitNode(valIdx),
              "..",
              nnkPrefix.newTree(
                ident"^",
                newIntLitNode(ends)
              )
            )
          )
        )
      # update the value index
      valIdx = ends
    else:
      let
        valIdxNode = newLit valIdx
        idxNode = if backwards: prefix(valIdxNode, "^") else: valIdxNode
      receiver(sym, nnkBracketExpr.newTree(nameIdent, idxNode))
    # with backwards we decrement towards the end,
    # increment otherwise
    valIdx += (if backwards: -1 else: 1)


proc unpackImpl*(data: NimNode, symbols: NimNode): NimNode =
  let lenPresent = symbols.len == 1 and symbols[0].kind == nnkIntLit
  # If we have only 1 value - we got number of variables to unpack
  if lenPresent:
    result = unpackWithLenImpl(data, symbols[0].intVal)
  else:
    result = newStmtList()
    template recvSV(sym, val: NimNode) =
      result.add newVarStmt(sym, val)
    unpackImplRec(data, symbols, result, recvSV)