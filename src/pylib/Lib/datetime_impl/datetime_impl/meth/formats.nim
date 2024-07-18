
include ./common
import ./isoformat
import ./require_time_module

using value: datetime # | date
func formatValue*(result: var string; value; specifier: string) =
  ## for std/strformat's fmt
  if specifier.len == 0:
    result.add isoformat.`$` value
    return
  result.add value.strftime(specifier)

using self: datetime # | date
func format*(self; format_spec = ""): string =
  result.formatValue(self, format_spec)
