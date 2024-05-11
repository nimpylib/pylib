
from std/strutils import strip
import ./bytesimpl

func strip*(self: PyBytes): PyBytes = bytes ($self).strip(true, true)
func lstrip*(self: PyBytes): PyBytes = bytes ($self).strip(trailing=false)
func rstrip*(self: PyBytes): PyBytes = bytes ($self).strip(leading=false)

converter asSet(s: PyBytes): set[char] =
  for c in s.chars:
    result.incl c
func strip*(self: PyBytes,  chars: PyBytes): PyBytes =
  bytes self.strip(chars=chars.asSet)
func lstrip*(self: PyBytes, chars: PyBytes): PyBytes =
  bytes self.strip(trailing=false, chars=chars.asSet)
func rstrip*(self: PyBytes, chars: PyBytes): PyBytes =
  bytes self.strip(leading=false, chars=chars.asSet)
