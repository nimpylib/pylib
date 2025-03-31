

type
  TestCase* = ref object of RootObj

func newTestCase*: TestCase = TestCase()
