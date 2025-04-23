## `PYTHON*` environment variables will be loaded iif pylibUsePyEnv is defined.
import ../../../version
import std/macros
#[
import std/macrocache
const fields = CacheSeq"sys.flags-fields"
export macrocache
]#
var fields*{.compileTime.} = newSeqOfCap[NimNode](18)

template addField(f) =
  static:
    const fname = astToStr(f)
    fields.add ident fname

template toCfgName(f): string = "pylibConfig" & astToStr(f)
template flag(f; defval=false) =
  const f*{.booldefine: f.toCfgName.} = defval
  addField f

template flagi(f; defval=0) =
  const f*{.intdefine: f.toCfgName.} = defval
  addField f

const PY_LONG_DEFAULT_MAX_STR_DIGITS = 4300  ## PY-DIFF: no use (PyLong is not implemented)

# Following defvals are according to Python/initconfig.c:_PyConfig_Read `if (config->isolated) {...`
flagi debug, int(not defined(release))
flagi inspect
flagi interactive
pysince(3,4): flagi isolated
flagi optimize, defined(release).int + defined(danger).int
flagi dont_write_bytecode, 1  ## PY_DIFF: default is 1, as we doesn't produce .pyc
flagi no_user_site, isolated
flagi no_site
flagi ignore_environment, int(defined(pylibUsePyEnv) or bool isolated)  ## PY-DIFF: we ignore `PYTHON*` env by default
flagi verbose
flagi bytes_warning
pysince(3,2): flagi quiet
flagi hash_randomization
pysince(3,7): flag  dev_mode
flagi utf8_mode
pysince(3,11): flag  safe_path, isolated!=0
pysince(3,11): flagi int_max_str_digits, PY_LONG_DEFAULT_MAX_STR_DIGITS
pysince(3,10): flagi warn_default_encoding


macro redefineFlags*(kws: varargs[untyped]) =
  ## used in intermediate file, which wanna define some runtime flags.
  ## due to `export except`'s behavior, unknown kws are just ignored.
  result = newStmtList()
  var exp = nnkExportExceptStmt.newTree ident"ct"
  for kw in kws:
    exp.add kw[0]
    result.add newLetStmt(
      kw[0].postfix"*", kw[1]
    )
  result.add exp

macro genFlagsObj* =
  ## generate `let flags* = ...`
  var ntup = newNimNode nnkTupleConstr
  for f in ct.fields:
    let val = ident(f.strVal)
    ntup.add nnkExprColonExpr.newTree(
      f, val
    )
  result = newLetStmt(ident("flags").postfix"*", ntup)

