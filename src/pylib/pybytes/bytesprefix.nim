
import ./bytesimpl
import ../translateEscape

func b*(c: static[char]): PyBytes = pybytes c
func b*(s: static[string]): PyBytes =
  ## XXX: Currently
  ## `\Uxxxxxxxx` and `\uxxxx` 
  ## is supported as an extension.
  const ns = translateEscape s
  pybytes ns

func br*(s: static[string]): PyBytes =
  pybytes s

template rawB(pre){.dirty.} =
  template pre*(s): PyBytes =
    bind br
    br s

rawB rb
rawB Rb
rawB Br
