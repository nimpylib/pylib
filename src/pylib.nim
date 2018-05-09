import strutils, math, sequtils, macros, unicode, tables, strformat, times, json
export math, tables
import pylib/[
  class, print, types, ops, string/strops, string/pystring, tonim, pyrandom]
export class, print, types, ops, strops, pystring, tonim, pyrandom

type
  Iterable*[T] = concept x
    for value in x:
      value is T

const
  True* = true
  False* = false

converter bool*[T](arg: T): bool =
  ## Converts argument to boolean
  ## checking python-like truthiness
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
  ## Python-like input procedure
  if prompt.len > 0:
    stdout.write(prompt)
  stdin.readLine()

proc all*[T](iter: Iterable[T]): bool =
  ## Checks if all values in iterable are truthy
  result = true
  for element in iter:
    if not bool(element):
      return false

proc any*[T](iter: Iterable[T]): bool =
  ## Checks if at least one value in iterable is truthy
  result = false
  for element in iter:
    if bool(element):
      return true


# Mimics Pythons divmod().
proc divmod*(a: int, b: int):     array[0..1, int]   = [int(a / b), int(a mod b)]
proc divmod*(a: int8, b: int8):   array[0..1, int8]  = [int8(a / b), int8(a mod b)]
proc divmod*(a: int16, b: int16): array[0..1, int16] = [int16(a / b), int16(a mod b)]
proc divmod*(a: int32, b: int32): array[0..1, int32] = [int32(a / b), int32(a mod b)]
proc divmod*(a: int64, b: int64): array[0..1, int64] = [int64(a / b), int64(a mod b)]


# Mimics Pythons loads() to load JSON.
proc loads*(buffer: string): JsonNode = parseJson(buffer)


# Mimic Pythons sys.* useful to query basic info of the system.
type VersionInfos = tuple[
  major: int8, minor: int8, micro: int8, releaselevel: string, serial: int8]

const version_info: VersionInfos = (
  major: NimMajor.int8, minor: NimMinor.int8,
  micro: NimPatch.int8, releaselevel: "final", serial: 0.int8)

type Sis = tuple[
  platform: string, maxsize: int64, version: string, version_info: VersionInfos,
  byteorder: string, copyright: string, hexversion: string, api_version: string]

const sys*: Sis = (  # From http://devdocs.io/python~3.6/library/sys
  platform:     hostOS,                          # Operating System.
  maxsize:      high(BiggestInt),                # Biggest Integer possible.
  version:      NimVersion,                      # SemVer of Nim.
  version_info: version_info,                    # Tuple VersionInfos.
  byteorder:    $cpuEndian,                      # CPU Endian.
  copyright:    "MIT",                           # Copyright of Nim.
  hexversion:   NimVersion.toHex.toLowerAscii(), # Version Hexadecimal string.
  api_version:  NimVersion                       # SemVer of Nim.
)


# Mimic Pythons platform.* useful to query basic info of the platform.
type Platforms = tuple[node: string, system: string, machine: string]

const platform*: Platforms = (system: hostOS, machine: hostCPU, processor: hostCPU)


# # Mimics Pythons `with open(file, mode='r') as file:` context manager.
# template with_open*(f: string, mode: char='r', statements: untyped): stmt =
#   echo "inside"
#   var fileMode: FileMode
#   case mode  # From http://devdocs.io/python~3.6/library/functions#open
#   of 'r': fileMode = FileMode.fmRead
#   of 'w': fileMode = FileMode.fmWrite
#   of 'a': fileMode = FileMode.fmAppend
#   of 'b': fileMode = FileMode.fmReadWrite
#   of 't': fileMode = FileMode.fmReadWrite
#   of '+': fileMode = FileMode.fmReadWrite
#   of 'x': fileMode = FileMode.fmReadWriteExisting
#   # 'U' is Deprecated on Python.
#   var file {.inject.} = open(f, fileMode)
#   defer: file.close()
#   statements
#
#
# # Mimics Pythons `timeit()`
# template timeit*(setup: string="discard", teardown: string="discard",
#                  number: int=1_000_000, statements: untyped): untyped =
#   defer: teardown
#   setup
#   let started = now()
#   for i in 0..number:
#     statements
#   echo fmt"{number} Repetitions on {now() - started}."
