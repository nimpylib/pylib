## to be imported by ./version
# Values for PY_RELEASE_LEVEL */

type
  PyReleaseLevelEnum*{.pure.} = enum
    alpha =  0xA
    beta =   0xB
    gamma =  0xC
    final =  0xF

const
  Major* = 0
  Minor* = 9
  Patch* = 12

  ReleaseLevel* = "alpha"
  Serial* = 0

  PyMajor*{.intdefine.} = 3
  PyMinor*{.intdefine.} = 14
  PyPatch*{.intdefine.} = 0
  PyReleaseLevel* = PyReleaseLevelEnum.final
  PySerial* = 0
