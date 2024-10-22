# DEV-NOTE: this definitions is in order of python's doc,
# also this's not a complete implementation

import std/macros

template genIsX(isX, typ){.dirty.} =
  macro isX*(obj: typed): bool =
    newLit obj.symKind == typ

func `==`(t: NimSymKind, expects: tuple[a, b: NimSymKind]): bool =
  t == expects[0] or t == expects[1]

const typeForPyDef = (nskProc, nskFunc)
genIsX ismodule,  nskModule
genIsX isclass,   nskType
genIsX ismethod,  nskMethod
genIsX isfunction,typeForPyDef

# TODO: after Python Generator is supported
# isgeneratorfunction
# isgenerator
# isasyncgenfunction 3.6
# isasyncgen
# ismethodwrapper 3.11
# isroutine
# isabstract
# ismethoddescriptor
# isdatadescriptor
# isgetsetdescriptor
# ismemberdescriptor


template nimpylib_is_coroutine_mark{.pragma.}

macro markcoroutinefunction*[T](obj: T): T =
  expectKind obj, RoutineNodes
  result = obj
  result.addPragma ident"nimpylib_is_coroutine_mark"

func iscoroutineImpl(obj: NimNode): bool =
  if obj.symKind != typeForPyDef:
    return
  # TODO: FIXME: I haven't found a way to get a symbol, but a untyped node
  let res = obj.getTypeInst().params[0]
  if res.kind == nnkBracketExpr:
    return res[0].eqIdent "Future"
  if res.eqIdent "Future":
    return true

macro iscoroutine*(obj: typed): bool =
  newLit iscoroutineImpl obj

macro iscoroutinefunction*(obj: typed): bool =
  result = newLit iscoroutineImpl obj
  if obj.hasCustomPragma nimpylib_is_coroutine_mark:
    return newLit true

template isawaitable*(obj: typed): bool = compiles(await obj)

# TODO: support them when types.PyFrame, PyTraceback are supported
template istraceback*(obj: typed): bool = obj is StackTraceEntry
template isframe*(obj: typed): bool = obj is TFrame

macro isbuiltin*(obj: typed): bool =
  newLit obj.getImpl().isNil


when isMainModule:
  import std/asyncdispatch
  proc f(){.inline,async.} = discard
  proc g() = discard
  static:
    echo iscoroutinefunction f
    echo iscoroutinefunction g
