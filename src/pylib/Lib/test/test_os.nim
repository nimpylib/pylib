
import ./import_utils
importTestPyLib os

suite "Lib/os":
  const fn = "tempfiletest"
  when not defined(js):
    ##[ XXX: NIM-BUG:
Error: internal error: genTypeInfo(tyUserTypeClassInst)
$nim/compiler/jstypes.nim(156, 22) compiler msg initiated here [MsgOrigin]
    ]##
    test "mkdir rmdir":
      const invalidDir = "No one will name such a dir"
      checkpoint "rmdir"
      expect FileNotFoundError:
        os.rmdir(invalidDir)

      checkpoint "mkdir"
      expect FileNotFoundError:
        # parent dir is not found
        os.mkdir(invalidDir + os.sep + "non-file")

test "os.path":
  ## only test if os.path is correctly export
  let s = os.path.dirname("1/2")
  check s == "1"
  check os.path.isdir(".")
  assert os.path.join("12", "ab") == str("12") + os.sep + "ab"

