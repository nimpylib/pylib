

import ./private/platformInfo
import ../pystring/strimpl
export strimpl
import std/strutils

func python_implementation*(): PyStr = str "PyNim"
func system*(): PyStr = str `platform.system`
const machineS = str hostCPU.toUpperAscii()
func machine*(): PyStr = machineS

