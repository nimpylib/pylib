
import ./import_utils
importTestPyLib os

suite "os.path":
  test "if export right":
    ## only test if os.path is correctly export
    let s = os.path.dirname("1/2")
    check s == "1"
    check os.path.isdir(".")
    assert os.path.join("12", "ab") == str("12") + os.sep + "ab"

  test "getxtime":    
    # TODO: more tests
    discard getctime(".")
