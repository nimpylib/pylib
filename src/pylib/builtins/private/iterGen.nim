
import std/macros


func capital(s: string): string =
  ## assume s[0].isLowerAscii()
  char(s[0].ord - 32) & s.substr(1)

# XXX: NIM-BUG: do not implememt via `template items`.
#  otherwise, when `for i in zip...`,
#  zip object initialization will be
#  wrongly placed in loop body
template makeIterable*(Typ){.dirty.} =
  iterator items*[T](x: Typ[T]): T =
    for i in x.iter(): yield i

macro genIter*(def) =
  ## used as pragma
  ##
  ## Generates code of non-reentrant iterable,
  ## according to an iterator.
  expectKind def, nnkIteratorDef
  let nameAstr = def[0]
  expectKind nameAstr, nnkPostfix
  let name = nameAstr[1]
  let
    genericParams = def[2]
    r_params = def[3]
    otherPragmas = def[4]
    body = def.body  # def[5]

  let rtype = r_params[0]

  let sName = name.strVal
  let typId = ident sName.capital()
  let makeIterableId = bindSym"makeIterable"
  result = newStmtList()
  result.add quote do:
    when not declared(`typId`):  # XXX: allow overload/defined types
      type `typId`[T] = object
        iter*: iterator(): `rtype`
      `makeIterableId` `typId`
      
  var funcDef = newProc(nameAstr, procType=nnkFuncDef, pragmas=otherPragmas)
  funcDef[2] = genericParams
  funcDef[3] = r_params.copy()
  # genericParams[0].kind == nnkIdentDefs 
  let funcResType = genericParams[0][0]
  funcDef[3][0] = nnkBracketExpr.newTree(typId, funcResType)
  # no need to strip doc manually,
  #  as `body` is of lambda iterator.
  let funcBody = quote do:
    result.iter = iterator(): `rtype` = `body`  
  funcDef.body = funcBody
  result.add funcDef
      
  result.add def
