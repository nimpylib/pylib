
const DenoDetectedJsExpr* = "typeof Deno !== 'undefined'"
when defined(js):
  let inDeno*{.importjs: DenoDetectedJsExpr.}: bool

