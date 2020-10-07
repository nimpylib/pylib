when defined(nimHasStrictFuncs):
  {.experimental: "strictFuncs".}

import std / [
  strutils, math, macros, unicode, tables, strformat, times, json
]
export math, tables

import pylib/[
  class, print, types, ops, unpack,
  string/strops, string/pystring,
  tonim, pyrandom, xrange, pytables
]
export
  class, print, types, ops, unpack, strops, pystring, tonim, pyrandom, xrange, pytables

when not defined(pylibNoLenient):
  {.warning: "'lenientops' module was imported automatically. Compile with -d:pylibNoLenient to disable it if you wish to do int->float conversions yourself".}
  import lenientops
  export lenientops

type
  Iterable*[T] = concept x  ## Mimic Pythons Iterable.
    for value in x:
      value is T

  Platform* = tuple[  ## Python-like platform.*
    system: string, machine: string, processor: string
  ]

  VersionInfo* = tuple[  ## Python-like sys.version_info
    major: int, minor: int, micro: int, releaselevel: string, serial: int
  ]

  Sys* = tuple[  ## Python-like sys.*
    platform: string, maxsize: int64, version: string, version_info: VersionInfo,
    byteorder: string, copyright: string, hexversion: string, api_version: string
  ]

  NoneType* = distinct bool

const
  # Python-like boolean literals
  True* = true ## True
  False* = false ## False
  None* = NoneType(false) ## Python-like None for special handling
  platform*: Platform = (system: hostOS, machine: hostCPU, processor: hostCPU)  ## Platform info.
  version_info*: VersionInfo = (
    major: NimMajor,
    minor: NimMinor,
    micro: NimPatch,
    releaselevel: "final",
    serial: 0
  )  ## Version information (SemVer).
  sys*: Sys = (
    platform:     hostOS,
    maxsize:      high(BiggestInt),
    version:      NimVersion,
    version_info: version_info,
    byteorder:    $cpuEndian,
    copyright:    "MIT",
    hexversion:   NimVersion.toHex.toLowerAscii(),
    api_version:  NimVersion
  )  ## From http://devdocs.io/python~3.7/library/sys


# https://github.com/nim-lang/Nim/issues/8197
#[
type
  HasLen = concept x
    x.len is int

  HasNotEqual = concept x
    x != 0 is bool

  HasMoreThan = concept x
    x > 0 is bool

  CanCompToNil = concept x
    x == nil is bool

converter bool*(arg: HasLen): bool = arg.len > 0
converter bool*(arg: HasNotEqual): bool = arg != 0
converter bool*(arg: HasMoreThan): bool = arg > 0 or arg < 0
converter bool*(arg: CanCompToNil): bool = arg != nil
]#

converter toBool*[T](arg: T): bool =
  ## Converts argument to boolean, checking python-like truthiness.
  # If we have len proc for this object
  when compiles(arg.len):
    arg.len > 0
  # If we can compare if it's not 0
  elif compiles(arg != 0):
    arg != 0
  # If we can compare if it's greater than 0
  elif compiles(arg > 0):
    arg > 0 or arg < 0
  # Initialized variables only
  elif compiles(arg != nil):
    arg != nil
  else:
    # XXX: is this correct?
    true

proc bool*[T](arg: T): bool =
  toBool(arg)

proc input*(prompt = ""): string =
  ## Python-like ``input()`` procedure
  if prompt.len > 0:
    stdout.write(prompt)
  stdin.readLine()

func all*[T](iter: Iterable[T]): bool =
  ## Checks if all values in iterable are truthy
  result = true
  for element in iter:
    if not bool(element):
      return false

func any*[T](iter: Iterable[T]): bool =
  ## Checks if at least one value in iterable is truthy
  result = false
  for element in iter:
    if bool(element):
      return true

iterator items*[T](getIter: proc(): iterator(): T): T =
  ## Special items() iterator for pylib internal iterators
  let iter = getIter()
  while (let x = iter(); not finished(iter)):
    yield x

# XXX: compiler says that list has side effects for some reason
proc list*[T](getIter: proc: iterator(): T): seq[T] =
  ## Special list() procedure for pylib internal iterators
  for item in items(getIter):
    result.add item

func filter*[T](comp: proc(arg: T): bool, iter: Iterable[T]): proc(): iterator(): T =
  ## Python-like filter(fun, iter)
  runnableExamples:
    proc isAnswer(arg: string): bool =
      return arg in ["yes", "no", "maybe"]

    let values = @["yes", "no", "maybe", "somestr", "other", "maybe"]
    let filtered = filter(isAnswer, values)
    doAssert list(filtered) == @["yes", "no", "maybe", "maybe"]

  result = proc(): iterator(): T =
    result = iterator(): T =
      for item in iter:
        if comp(item):
          yield item

func filter*[T](arg: NoneType, iter: Iterable[T]): proc(): iterator(): T =
  ## Python-like filter(None, iter)
  runnableExamples:
    let values = @["", "", "", "yes", "no", "why"]
    let filtered = list(filter(None, values))
    doAssert filtered == @["yes", "no", "why"]

  result = filter[T](pylib.bool, iter)

func divmod*(a, b: SomeInteger): (int, int) =
  ## Mimics Pythons ``divmod()``.
  result = (int(a / b), int(a mod b))

func chr*(a: SomeInteger): string =
  $Rune(a)

template makeConv(name, call: untyped, len: int, pfix: string) =
  func `name`*(a: SomeInteger): string =
    # Special case
    if a == 0:
      return `pfix` & "0"
    result = call(
      when a isnot SomeUnsignedInt: 
        abs(a) 
      else: 
        a, 
      `len`).toLowerAscii().strip(chars = {'0'}, trailing = false)
    # Do it like in Python - add - sign
    result.insert(`pfix`)
    if a < 0:
      result.insert "-"

# Max length is derived from the max value for uint64
makeConv(oct, toOct, 30, "0o")
makeConv(bin, toBin, 70, "0b")
makeConv(hex, toHex, 20, "0x")

func ord*(a: string): int =
  result = system.int(a.runeAt(0))

proc json_loads*(buffer: string): JsonNode =
  ## Mimics Pythons ``json.loads()`` to load JSON.
  result = parseJson(buffer)

import times

template timeit*(repetitions: int, statements: untyped): untyped =
  ## Mimics Pythons ``timeit.timeit()``, output shows more information than Pythons.
  bind times.`$`
  let
    started = now()
    cpuStarted = cpuTime()
  for i in 0 .. repetitions:
    statements
  echo "$1 TimeIt: $2 Repetitions on $3, CPU Time $4.".format(
    $now(), repetitions, $(now() - started), $(cpuTime() - cpuStarted))

import os

template with_open*(f: string, mode: char | string, statements: untyped): untyped =
  ## Mimics Pythons ``with open(file, mode='r') as file:`` context manager.
  ## Based on http://devdocs.io/python~3.7/library/functions#open
  bind fileExists
  block:  # Error: redefinition of 'file'.
    let pyfileMode = case $mode  # Allows generinc char|string
      of "w": FileMode.fmWrite
      of "a": FileMode.fmAppend
      of "x": FileMode.fmReadWriteExisting
      of "b", "t", "+": FileMode.fmReadWrite
      else:   FileMode.fmRead
    # Change "Error: cannot open: foo" for Python-copied traceback.
    if pyfileMode == FileMode.fmRead or pyfileMode == FileMode.fmReadWriteExisting:
      doAssert fileExists(f), """

      Traceback (most recent call last):
          FileNotFoundError: [Errno 2] No such file or directory: """ & f
    # Python people always try to use file.read() that wont exist on Nim.
    template read(fileType: File): string {.used.} = fileType.readAll()
    var file {.inject.} = open(f, pyfileMode)
    try: # defer: wont like top level,because is a template itself.
      statements
    finally:
      file.close()  # file variable not declared after this.

template with_NamedTemporaryFile*(statements: untyped): untyped =
  ## Mimic Python ``with tempfile.NamedTemporaryFile() as file:`` context manager.
  ## Can be used like ``with_NamedTemporaryFile(): echo file.read()``.
  block:  # Error: redefinition of 'file'.
    let path = getTempDir() / $rand(100_000..999_999)
    when not defined(release): echo path
    # Python people always try to use file.read() that wont exist on Nim.
    template read(fileType: File): string {.used.} = fileType.readAll()
    var file {.inject.} = open(path, fmReadWrite)
    try: # defer: wont like top level,because is a template itself.
      statements
    finally:
      file.close()  # file variable not declared after this.
      discard tryRemoveFile(path)

template with_TemporaryDirectory*(statements: untyped): untyped =
  ## Mimic Python ``with tempfile.TemporaryDirectory():`` context manager.
  ## Can be used like ``with_TemporaryDirectory(): echo name``.
  block:  # Error: redefinition.
    let name {.inject.} = getTempDir() / $rand(100_000..999_999)
    when not defined(release): echo name
    if not existsOrCreateDir(name): # Returns true if directory already exists.
      # Python people always try to use file.read() that wont exist on Nim.
      template read(fileType: File): string {.used.} = fileType.readAll()
      try: # defer: wont like top level,because is a template itself.
        statements
      finally:
        try: removeDir(name) except: discard

template pass*(_: untyped) = discard # pass 42

template lambda*(code: untyped): untyped =
  (proc (): auto = code)  # Mimic Pythons Lambda

template `:=`*(name, value: untyped): untyped =
  ## Mimic Pythons Operator.
  ## Creates new variable `name` and assign `value` to it.
  (var name = value; name)
