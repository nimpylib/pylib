discard """
  cmd: "nim c --hints:off -d:testing $options $file"
  nimout: '''
abc
'''
"""

import pylib

static:
  #print("a1 ", endl="")  # XXX: cannot impl
  print("abc")


