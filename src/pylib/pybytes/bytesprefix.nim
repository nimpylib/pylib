
import ./bytesimpl
import ../translateEscape

func b*(c: char{lit}): PyBytes = pybytes c
func b*(s: static[string]{lit}): PyBytes =
  ## XXX: Currently
  ## `\Uxxxxxxxx` and `\uxxxx` 
  ## is supported as an extension.
  const ns = translateEscape s
  pybytes ns

func br*(s: string{lit}): PyBytes =
  pybytes s

template rawB(pre){.dirty.} =
  template pre*(s): PyBytes =
    bind br
    br s

rawB rb
rawB Rb
rawB Br
