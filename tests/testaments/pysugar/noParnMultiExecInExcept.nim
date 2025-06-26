discard """
  action: "compile"
"""
import pylib/version

pysince(3,14):
  import pylib/pysugar
  def f():
    try: pass
    except KeyError, ValueError: pass
  f()
