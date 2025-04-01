
type
  Cleanup = proc ()
  TestCase* = ref object of RootObj
    `private.testMethodName`*: string
    `private.cleanups`*: seq[Cleanup]

func newTestCase*(methodName="runTest"): TestCase =
  result = TestCase()
  result.`private.testMethodName` = methodName
