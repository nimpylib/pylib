##[Test the errno module
   Roger E. Masse
]##

import ./import_utils
importTestPyLib errno

# std_c_errors = ["EDOM", "ERANGE"]

template errnoEq(sym) =
  let s = astToStr(sym)
  check s == errorcode[sym]

suite "ErrnoAttributeTests":
  test "using_errorcode":
    # Every key value in errno.errorcode should be on the module.
    #for value in errno.errorcode.values(): check hasattr(errno, value)
    errnoEq EDOM
    errnoEq ERANGE


#[
suite "ErrorcodeTests":
  test "attributes_in_errorcode":
    for attribute in errno.__dict__.keys():
      if attribute.isupper():
        self.assertIn(getattr(errno, attribute), errno.errorcode,
                              "no %s attr in errno.errorcode" % attribute)
]#

