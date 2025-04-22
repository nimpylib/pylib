
import std/typeinfo
export typeinfo

type
  HookProc* = proc (event: string; args: varargs[Any])
  HookEntry* = tuple[
    hookCFunction: HookProc,
    userData: Any,
  ]

