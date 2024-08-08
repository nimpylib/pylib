
when defined(js):
  let inDeno*{.importjs: "typeof Deno === 'undefined'".}: bool

