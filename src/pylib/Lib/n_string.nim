
from std/unicode import nil
from std/strutils import nil
import std/tables
import ../pystring


import string_impl/[
    capwordsImpl, consts, templateImpl
    ]
export genCapwords
export consts
export templateImpl except genSubstitute

genCapwords string, string,
  unicode.split, strutils.split, unicode.capitalize, strutils.strip


genSubstitute(Table, string, substitute, raiseKeyError, invalidFormatString)
genSubstitute(Table, string, safe_substitute, noraiseKeyError, supressInvalidFormatString)
