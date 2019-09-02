import strutils, math, sequtils, macros, unicode, tables, strformat, times, json
export math, tables
import pylib/[
  class, print, types, ops, string/strops, string/pystring, tonim, pyrandom]
export class, print, types, ops, strops, pystring, tonim, pyrandom

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

template with_open*(f: string, mode: char, statements: untyped): untyped =
  ## Mimics Pythons ``with open(file, mode='r') as file:`` context manager.
  ## Based on http://devdocs.io/python~3.7/library/functions#open
  var fileMode: FileMode
  case mode
  of 'r': fileMode = FileMode.fmRead
  of 'w': fileMode = FileMode.fmWrite
  of 'a': fileMode = FileMode.fmAppend
  of 'b': fileMode = FileMode.fmReadWrite
  of 't': fileMode = FileMode.fmReadWrite
  of '+': fileMode = FileMode.fmReadWrite
  of 'x': fileMode = FileMode.fmReadWriteExisting
  else:   fileMode = FileMode.fmRead
  # 'U' is Deprecated on Python.
  var file {.inject.} = open(f, fileMode)
  defer: file.close()
  statements
