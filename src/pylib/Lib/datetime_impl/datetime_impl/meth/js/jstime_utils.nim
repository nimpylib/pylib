
when not defined(js):
  {.error: "JS backend only".}


func getTimeZoneName*: cstring =
  {.emit: [result,
    " = Intl.DateTimeFormat().resolvedOptions().timeZone"].}


