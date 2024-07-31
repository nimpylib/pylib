
import std/unicode

const
  unicodeSpaces* = [
    Rune 0x00009,
    Rune 0x0000A,
    Rune 0x0000B,
    Rune 0x0000C,
    Rune 0x0000D,
    Rune 0x0001C,
    Rune 0x0001D,
    Rune 0x0001E,
    Rune 0x0001F,
    Rune 0x00020,
    Rune 0x00085,
    Rune 0x000A0,
    Rune 0x01680,
    Rune 0x02000,
    Rune 0x02001,
    Rune 0x02002,
    Rune 0x02003,
    Rune 0x02004,
    Rune 0x02005,
    Rune 0x02006,
    Rune 0x02007,
    Rune 0x02008,
    Rune 0x02009,
    Rune 0x0200A,
    Rune 0x02028,
    Rune 0x02029,
    Rune 0x0202F,
    Rune 0x0205F,
    Rune 0x03000,
  ] ##[
    This differs Nim's unicodeSpaces(inner symbol) std/unicode.
    This has foour more characters than the latter:
    `\x1C`, `\x1D`, `\x1E`, `\x1F`
  ]##

