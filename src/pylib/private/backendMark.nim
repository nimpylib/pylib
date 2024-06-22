
import std/macros

type
  CompileBackend*{.pure.} = enum
    # keep consist with `defined` name
    c = "C"
    cpp = "C++"
    objc = "Object-C"
    js = "JavaScript"
    nimscript = "NimScript"

const
  BackendsDet: array[CompileBackend, bool] = [
    defined(c),
    defined(cpp),
    defined(objc),
    defined(js),
    defined(nimscript),
  ]

template inBackend(backend: CompileBackend): bool = BackendsDet[backend]
func inBackend(backends: openArray[CompileBackend]): bool =
  result = false
  for b in backends:
    if BackendsDet[b]:
      return true

const NotSupportMsgTempl = "The symbol is not supported in the backend: "
template notSupportMsgNode(s): NimNode = newLit(NotSupportMsgTempl & s)
const
  DocSep = "\n\n"
  NotSupportDocTempl = ".. hint:: not available in "
template notSupportDoc(s): untyped = NotSupportDocTempl & s & " backend"

func wrap1Impl(back: NimNode): NimNode =
  quote do: CompileBackend.`back`

macro wrap1(back): CompileBackend = wrap1Impl back

func insertNotSuppPragma(res: NimNode, backendName: string) =
  res.addPragma nnkExprColonExpr.newTree(
    ident"error",
    notSupportMsgNode(backendName)
  )

func refineDoc(res: NimNode, backendName: string) =
  let n = notSupportDoc backendName
  var body = res.body
  if body[0].kind != nnkCommentStmt:
    body.insert(0, newCommentStmtNode n)
  else: body[0].strVal = body[0].strVal & DocSep & n

template noBackendImplBody(def, backend) =
  result = def
  let backendName = $backend
  result.refineDoc backendName
  if not inBackend backend:
    return
  result.insertNotSuppPragma backendName
func noBackendImpl(def: NimNode, backend: CompileBackend): NimNode =
  noBackendImplBody def, backend

macro noBackendAux(backend: static[CompileBackend]; def) =
  noBackendImpl(def, backend)

template noBackend1(targetBackend; def): untyped =
  bind noBackendAux, wrap1
  noBackendAux(def, wrap1(targetBackend))

template noJsBackend*(def) =
  bind noBackend1
  noBackend1(js, def)

template noNimsBackend*(def) =
  bind noBackend1
  noBackend1(nimscript, def)

type Backends = openArray[CompileBackend]
func `$`(backends: Backends): string =
  let le = backends.len
  if unlikely(le == 0): return
  result.add $backends[0]
  for i in 1..<le:
    result.add ", "
    result.add $backends[i]

func noBackendImpl(def: NimNode, backends: Backends): NimNode =
  noBackendImplBody def, backends

macro noBackendAux(backends: static[Backends]; def) =
  noBackendImpl(def, backends)

func wrapsImpl(backends: NimNode): NimNode =
  expectKind backends, nnkBracket
  backends[0] = newDotExpr(bindSym"CompileBackend", backends[0])
  backends

macro wrapsAux(backends: untyped): untyped =
  wrapsImpl backends

template noBackends*(backends: untyped, def) =
  ## does the same as noBackend(...)
  bind noBackendAux, wrapsAux
  noBackendAux(wrapsAux backends,  def)

template noWeirdBackend*(def) =
  bind noBackends
  noBackends([js, nimscript], def)

macro wrapAux(backends: untyped): untyped =
  if backends.kind == nnkBracket:
    wrapsImpl backends
  else:
    wrap1Impl backends

template noBackend*(backends: untyped, def) =
  bind noBackendAux, wrapAux
  noBackendAux(wrapAux backends,  def)


when isMainModule:
  #func f{.noWeirdBackend.} = discard
  func f*{.noBackend([js]).} = discard
  f()
