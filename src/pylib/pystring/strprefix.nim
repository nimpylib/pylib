
import ./strimpl
import ../translateEscape

func u*(s: static[string]): PyStr =
  const ns = translateEscape s
  str(ns)

func u*(a: static char): PyStr = str(a)
