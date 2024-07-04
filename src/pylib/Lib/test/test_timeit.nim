 
import ./import_utils
importTestPyLib timeit
importPyLib time

test "Lib/timeit":
  def a_little_sleep():
    "sleep around 0.001 milsecs."
    # note Nim's os.sleep's unit is milsec,
    # while Python's time.sleep's is second.
    sleep(0.001)

  check timeit(a_little_sleep, number=10) >= 0.01