import strutils, math, sequtils, macros, unicode, tables, strformat, times, json, lenientops
export math, tables, lenientops
import pylib/[
  class, print, types, ops, string/strops, string/pystring, tonim, pyrandom]
export class, print, types, ops, strops, pystring, tonim, pyrandom

{.warning: "Math with mixed float and int enabled. AutoConversion from int to float enabled, convert explicitly to skip.".}

type
  Iterable*[T] = concept x  ## Mimic Pythons Iterable.
    for value in x:
      value is T
  Platforms* = tuple[
    system: string, machine: string, processor: string
  ]  ## Mimic Pythons platform.* useful to query basic info of the platform.
  VersionInfos* = tuple[
    major: int8, minor: int8, micro: int8, releaselevel: string, serial: int8
  ]  ## Mimic Pythons sys.* useful to query basic info of the system.
  Sis* = tuple[
    platform: string, maxsize: int64, version: string, version_info: VersionInfos,
    byteorder: string, copyright: string, hexversion: string, api_version: string
  ]  ## Mimic Pythons sys.* useful to query basic info of the system.

const
  True* = true    ## True with Capital leter like Python.
  False* = false  ## False with Capital leter like Python.
  platform*: Platforms = (system: hostOS, machine: hostCPU, processor: hostCPU)  ## Platform info.
  version_info*: VersionInfos = (
    major: NimMajor.int8,
    minor: NimMinor.int8,
    micro: NimPatch.int8,
    releaselevel: "final",
    serial: 0.int8
  )  ## Version information (SemVer).
  sys*: Sis = (
    platform:     hostOS,                          # Operating System.
    maxsize:      high(BiggestInt),                # Biggest Integer possible.
    version:      NimVersion,                      # SemVer of Nim.
    version_info: version_info,                    # Tuple VersionInfos.
    byteorder:    $cpuEndian,                      # CPU Endian.
    copyright:    "MIT",                           # Copyright of Nim.
    hexversion:   NimVersion.toHex.toLowerAscii(), # Version Hexadecimal string.
    api_version:  NimVersion                       # SemVer of Nim.
  )  ## From http://devdocs.io/python~3.7/library/sys


converter bool*[T](arg: T): bool =
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
  else:
    not arg.isNil()

converter toStr[T](arg: T): string = $arg

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

func divmod*(a, b: SomeInteger): array[0..1, int] =
  ## Mimics Pythons ``divmod()``.
  [int(a / b), int(a mod b)]

proc json_loads*(buffer: string): JsonNode =
  ## Mimics Pythons ``json.loads()`` to load JSON.
  parseJson(buffer)

template timeit*(repetitions: int, statements: untyped): untyped =
  ## Mimics Pythons ``timeit.timeit()``, output shows more information than Pythons.
  let
    started = now()
    cpuStarted = cpuTime()
  for i in 0..repetitions:
    statements
  echo "$1 TimeIt: $2 Repetitions on $3, CPU Time $4.".format(
    now(), repetitions, now() - started, cpuTime() - cpuStarted)

template with_open*(f: string, mode: char | string, statements: untyped): untyped =
  ## Mimics Pythons ``with open(file, mode='r') as file:`` context manager.
  ## Based on http://devdocs.io/python~3.7/library/functions#open
  block:  # Error: redefinition of 'file'.
    let pyfileMode = case $mode  # Allows generinc char|string
      of "w": FileMode.fmWrite
      of "a": FileMode.fmAppend
      of "x": FileMode.fmReadWriteExisting
      of "b", "t", "+": FileMode.fmReadWrite
      else:   FileMode.fmRead
    # Change "Error: cannot open: foo" for Python-copied traceback.
    if pyfileMode == FileMode.fmRead or pyfileMode == FileMode.fmReadWriteExisting:
      doAssert existsFile(f), """

      Traceback (most recent call last):
          FileNotFoundError: [Errno 2] No such file or directory: """ & f
    # Python people always try to use file.read() that wont exist on Nim.
    template read(fileType: File): string = fileType.readAll()
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
    template read(fileType: File): string = fileType.readAll()
    var file {.inject.} = open(path, fmReadWrite)
    try: # defer: wont like top level,because is a template itself.
      statements
    finally:
      file.close()  # file variable not declared after this.
      discard tryRemoveFile(path)

template pass*(_: any) = discard # pass 42
template pass*() = discard       # pass()

template lambda*(code: untyped): untyped =
  ( proc (): auto = code )  # Mimic Pythons Lambda

template `import`*(module: string): untyped = import module  # Mimic Pythons __import__()

macro `:=`*(variable: string, value: SomeNumber|char|string): untyped =
  ## Mimic Pythons Walrus Operator. Creates new variable from string and assign value.
  var v: string
  case value.kind
  of nnkCharLit: v = "char(" & $value.intVal & ")"
  of nnkIntLit..nnkUInt64Lit: v = $value.intVal
  of nnkFloatLit..nnkFloat64Lit: v = $value.floatVal
  of nnkStrLit..nnkTripleStrLit: v = "\"\"\"" & value.strVal & "\"\"\""
  else: discard # Limited by argument type anyways.
  parseStmt "(var " & $variable & "=" & v & ";" & $variable & ")"
