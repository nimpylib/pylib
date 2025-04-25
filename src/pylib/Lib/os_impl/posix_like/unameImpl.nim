
import ./pyCfg
importConfig [os]
template genUnameResult(S){.dirty.} =
  type uname_result* = tuple[
    sysname,
    nodename,
    release,
    version,
    machine: S
  ]
when HAVE_UNAME:
  import std/posix
  import ./errnoHandle
  proc utsFieldToString[T](field: T): string =
    # Implementation of utsFieldToString goes here
    when T is array:  # array of char
      result = newStringOfCap(field.len)
      var i = 0
      while field[i] != '\0':
        assert i < field.len
        result.add field[i]
        i.inc
    else: $field
  template posix_uname(u): cint =
    bind uname
    uname(u)
  template genUname*(S){.dirty.} =
    bind posix_uname, utsFieldToString, Utsname
    bind genUnameResult
    genUnameResult(S)
    proc uname*(): uname_result =
      var u{.noInit.}: Utsname
      let res = posix_uname(u)
      if res < 0:
        raiseErrno()
      template SET(field) =
        result.field = S utsFieldToString(u.field)
      {.push hint[ConvFromXtoItselfNotNeeded]: off.}
      SET sysname
      SET nodename
      SET release
      SET version
      SET machine
      {.pop.}

elif InJs:
  import ../common
  template genUname*(S){.dirty.} =
    bind genUnameResult
    genUnameResult(S)
    proc uname*(): uname_result =
      proc getSysname: cstring{.importInNodeModOrDeno(os, "type", "build.os$").}
      proc getNodename: cstring{.importDenoOrNodeMod(os, hostname).}
      proc getRelease: cstring{.importInNodeModOrDeno(os, release, osRelease).}
      proc getVersion: cstring{.importNode(os, version).}
      proc getMachine: cstring{.importInNodeModOrDeno(os, machine, "build.arch$").}
      template SET(field) =
        result.field = S $`get field`()
      SET sysname
      SET nodename
      SET release
      SET version
      SET machine

      #SET sysname, `type`, `build.os` # attr # "windows": "Windows_NT", caption
else:
  template genUname*(S){.dirty.} =
    bind genUnameResult
    genUnameResult(S)
    # do nothing other than define the type

when isMainModule:
  genUname string
  echo uname()
