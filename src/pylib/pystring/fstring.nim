## f-string
## 
## a string literal with a prefix of fr, Fr, rf of Rf
##  behaves as if with a prefix of `strformat.fmt`.
## 
## and f"xxx" is different,
##  where the escaped literals in string will be interpreted.
## 

from std/strformat import fmt
import std/macros 
import ./strimpl
import ../translateEscape

template genFR(sym){.dirty.} =
  macro sym*(pattern: static[string]): PyStr = quote do: fmt`pattern`

genFR fr 
genFR Fr 
genFR rf 
genFR Rf

template f*(s: static[string]): PyStr =
  ## Python F-String.
  ## 
  ## *Not* the same as Nim's fmt"xxx"
  ##  as that's equal to `fmt r"xxx"`, a.k.a fr"xx" in Python
  ## 
  ## Any escape-translation error is reported at compile-time,
  ##   with information of filename and line number
  ## 
  ## ## Unicode
  ## `\Uhhhhhhhh` is supported as Python's,
  ## while Nim's `\U{...}` is unsupported but `\u{...}` is reserved
  ## 
  ## ## oct
  ##  `\\[0-7]{1,3}` in f-string will be interpreted as octal digit as Python,
  ## instead of decimal as Nim.
  ## 
  ## ## multiline
  ## the following shows the deature of Nim's multiline string
  ##       which is different from Python's
  ## ```Nim
  ## assert "" == """
  ## """
  ## ```
  runnableExamples:
    assert f"\n" == "\n"
    assert f"123{'a'}\n456" == "123a\n456"

    assert f"\U0001f451" == "👑"

    assert f"\10" == "\x08"   # nim's "\10" means chr(10)

    assert f"""\t123
""" == "\t123\n"  # even if the source code's newline is crlf.
  bind fmt
  fmt translateEscapeWithErr s
