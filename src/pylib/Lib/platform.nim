

import ./private/platformInfo
import ../pystring/strimpl
export strimpl

proc version*(): PyStr = str `platform.version`()

func python_implementation*(): PyStr{.inline.} = str "PyNim"
func system*(): PyStr{.inline.} = str `platform.system`

const machineS = hostCPU
#[ doc says:

```
Possible values:
  "i386", "amd64",
  "powerpc", "powerpc64", "powerpc64el",

  "alpha", "sparc", "loongarch64".
  "mips", "mipsel", "mips64", "mips64el", 
  "arm", "arm64", "riscv32", "riscv64",
```
]#
# refer to compiler/platform.nim,
# there're more

# compiler/semfold.nim
# proc getConstExpr(m: PSym, n: PNode; idgen: IdGenerator; g: ModuleGraph): PNode
# of mHostCPU: result = newStrNodeT(platform.CPU[g.config.target.targetCPU].name.toLowerAscii, n, g)

when defined(windows):
  import std/strutils
  template winNormMachine(machine): string =
    case machine
    of "i386": "x86"
    of "alpha": "Alpha"
    elif machine.startsWith"powerpc": "PowerPC"
    elif machine.startsWith"mips": "MIPS"
    #elif machine.startsWith"arm": machine.toUpperAscii
    else:  # including ia64, arm[64], amd64
      machine

func machine*(): PyStr{.inline.} =
  when defined(windows):
    winNormMachine machineS
  else:
    case machineS
    of "amd64": "x86_64"
    of "arm64": "aarch64"
    else: machineS

