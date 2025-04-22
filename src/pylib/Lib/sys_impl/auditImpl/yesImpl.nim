
import ./types
import ../../../pyerrors/rterr
import std/lists
import std/locks
import std/macros

template mytoAny[T](x: T): Any =
  bind toAny
  var tx = x
  toAny(tx)

proc nodeToAny(n: NimNode): NimNode = newCall(bindSym"mytoAny", n)

proc callVarargImpl(call, arg1, vargs: NimNode): NimNode =
  # NIM-BUG: vargs will become Sym of nil when doc
  expectKind vargs, nnkBracket
  result = newCall(call, arg1)
  for i in vargs:
    result.add i.nodeToAny

macro callVararg(call, arg1, vargs: typed) =
  callVarargImpl(call, arg1, vargs)

macro callWithExtraVararg(call, arg1, vargs: typed, extra: Any) =
  result = callVarargImpl(call, arg1, vargs)
  result.add extra

template initHookList(): SinglyLinkedList[HookEntry] = initSinglyLinkedList[HookEntry]()
template toHookEntry(v: HookProc, userData: Any): HookEntry = (v, userData)

type
  PyRuntimeState = object
    audit_hooks*: tuple[
      head: SinglyLinkedList[HookEntry],
      mutex: Lock,
    ]

var runtime = PyRuntimeState(
  audit_hooks: (
    head: initHookList(),
    mutex: Lock(),
  )
)
runtime.audit_hooks.mutex.initLock()

var interp = (
  audit_hooks: newSeq[HookProc]()
)
proc PyDTrace_AUDIT_ENABLED(): bool = false  ## Currently not implemented
proc should_audit(): bool{.inline.} =
  not runtime.audit_hooks.head.head.isNil or
    interp.audit_hooks.len > 0 or
    PyDTrace_AUDIT_ENABLED()

template PySys_AuditImpl(event: string, args: untyped) =
  ## `PySys_Audit`/`sys_audit_tstate` EXT. CPython C-API
  bind runtime, callWithExtraVararg, callVararg, items
  for e in runtime.audit_hooks.head.items:
    callWithExtraVararg(
      e.hookCFunction,
      event, args, e.userData)

  #[if dtrace: ...]#

  # Call interpreter hooks
  for hook in interp.audit_hooks:
    callVararg(hook, event, args)

template PySys_Audit*(event: string, args: varargs[typed]) =
  bind PySys_AuditImpl
  PySys_AuditImpl(event, args)

proc add_audit_hook_entry_unlocked(runtime: var PyRuntimeState, entry: HookEntry) =
  runtime.audit_hooks.head.append entry

template auditAddAuditHook(exc){.dirty.} =
  ## `PySys_Audit` EXT. CPython C-API
  try:
    PySys_Audit("sys.addaudithook")
  except exc:
    # We do not report errors derived from exc
    discard

proc PySys_AddAuditHook*(hook: HookProc, userData = default Any) =
  ## `PySys_Audit` EXT. CPython C-API
  auditAddAuditHook RuntimeError

  withLock runtime.audit_hooks.mutex:
    add_audit_hook_entry_unlocked(runtime, hook.toHookEntry userData)


proc addaudithook*(hook: HookProc) =
  auditAddAuditHook CatchableError
  interp.audit_hooks.add hook

template audit*(event: string, args: varargs[typed]) =
  bind should_audit, PySys_AuditImpl
  if should_audit():
    PySys_AuditImpl(event, args)

const ClearAuditHooksName = "cpython._PySys_ClearAuditHooks"
proc PySys_ClearAuditHooks() =
  # TODO: after config.verbose
  #if config.verbose: PySys_WriteStderr("# clear sys.audit hooks\n")
  try: PySys_Audit(ClearAuditHooksName)
  except Exception: discard

when (NimMajor, NimMinor, NimPatch) >= (2, 1, 1):
  ## XXX: FIXED-NIM-BUG: though nimAllowNonVarDestructor is defined at least since 2.0.6,
  ## it still cannot be compiled till abour 2.1.1
  proc `=destroy`*(self: PyRuntimeState) = PySys_ClearAuditHooks()
else:
  proc `=destroy`*(self: var PyRuntimeState) = PySys_ClearAuditHooks()

when isMainModule:
  addaudithook do (event: string, _: varargs[Any]):
    assert event == ClearAuditHooksName
