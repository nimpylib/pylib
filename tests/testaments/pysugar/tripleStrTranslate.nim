
discard """
  output: '''
true
true
'''
"""

import pylib/pysugar

def f(): return """\r"""

def g():
    """NOTE: in Python this returns '\n\r' """
    return """
\r"""

echo f() == "\r"
echo g() == "\r"
