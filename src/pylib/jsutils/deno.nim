
const DenoDetectedJsExpr* = "typeof Deno !== 'undefined'"
when defined(js):
  when defined(nodejs):
    let inDeno* = false
  else:
    let inDeno*{.importjs: DenoDetectedJsExpr.}: bool

