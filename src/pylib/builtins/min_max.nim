
import std/macros
import std/tables
import std/hashes

import std/options

import ../collections_abc
import ../noneType
import ./iter_next
export iter_next.items

proc hash(nn: NimNode): Hash =
  if nn.len == 0:
    if nn.kind == nnkSym:
      hash signatureHash(nn)  ## for table
    else:
      hash nn.strVal
  else:
    hash ""

template noDefault(kw; symName) =
  if ident"default" in kw:
    error "TypeError: Cannot specify a default for " & symName & "() with multiple positional arguments"

let keyId{.compileTime.} = ident"key"

template addKeyIfExist(result; kw) =
  if keyId in kw:
    result.add nnkExprEqExpr.newTree(keyId, kw[keyId])

type
  PyLibKey*[T, R] = proc (x: T): R

template withDefaultImpl(resultExpr){.dirty.} =
  result = default
  for i in it:
    result = resultExpr

template withoutDefaultImpl(resultExpr; symName){.dirty.} =
  let ite = iter(it)
  var res = nextImpl ite
  if res.isNone:
    raise newException(ValueError, symName & "() iterable argument is empty")
  result = res.unsafeGet
  while true:
    res = nextImpl(ite)
    if res.isNone:
      return
    result = resultExpr

template cmpByKey[T](dir, key; a, b: T): T =
  if dir(key(a), key(b)): a
  else: b

template gen(sym, dir, symName){.dirty.} =
  ## min/max(a, b) is alreadly defined by `system`
  func sym*[T; R](a, b: T; key: PyLibKey[T, R]): T = cmpByKey(dir, key, a, b)
  func sym*[T](a, b: T; key: NoneType): T = sym(a, b)

  func sym*[T](a, b, c: T; args: varargs[T]): T =
    result = sym(sym(a, b), c)
    for i in args: result = sym(result, i)


  proc sym*[T](it: Iterable[T], key = None): T =
    withoutDefaultImpl sym(result, res.unsafeGet), symName

  proc sym*[T; R](it: Iterable[T],
      key: PyLibKey[T, R]): T =
    withoutDefaultImpl cmpByKey(dir, key, result, res.unsafeGet), symName


  proc sym*[T](it: Iterable[T]; default: T, key = None): T =
    withDefaultImpl sym(result, i)

  proc sym*[T; R](it: Iterable[T]; default: T;
      key: PyLibKey[T, R]): T =
    withDefaultImpl cmpByKey(dir, key, result, i)

  macro sym*(kwargs: varargs[untyped]): untyped =
    let nka = kwargs.len

    var
      args = newSeqOfCap[NimNode] nka
      kw = newTable[NimNode, NimNode]()
    for i in kwargs:
      if i.kind == nnkExprEqExpr:
        kw[i[0]] = i[1]
      else:
        args.add i

    let
      nargs = args.len
      symId = bindSym symName

    case nargs
    of 0:
      error "TypeError: " & symName & " expected at least 1 argument, got 0", kwargs
    of 1:
      # return newCall(symId, kwargs)
      let
        obj = args[0]
        res = newCall(symId, kwargs)
      return quote do:
        when compiles(`res`):
          # Why not "`obj` of Iterable":
          #   Error (Iterable's generic type has to be explictly written)
          `res`
        else:
          {.error: "TypeError: '" & $typeof(`obj`) & "' object is not iterable".}
    of 2:
      noDefault kw, symName

      result = newCall(
        symId,
        args[0], args[1]
      )

      result.addKeyIfExist kw
    else:
      noDefault kw, symName

      result = newStmtList()
      let resId = genSym(nskVar, symName)
      result.add newVarStmt(resId, args[0])
      for i in 1..<nargs:
        var call = newCall(symId, resId, args[i])
        call.addKeyIfExist kw
        result.add newAssignment(resId, call)


gen max, `>`, "max"
gen min, `<`, "min"

when isMainModule:
  let ls = [1, 2, -1]
  echo max ls
