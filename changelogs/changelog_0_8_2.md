
# v0.8.2 - 2024-04-10


## Fixes for inconsistence with Python
- `f"xxx"` is no longer the same as `fr"xxx"` (as it always used to be). The escape chars in string will be translated now.

- `len` for empty ranges, e.g. `len(range(4,0))` now give `0` as Python does. (instead of an negative result)

- max/min on empty ranges, e.g. `max(range(4,0))`, now correctly raises `ValueError`

## Feature additions

- support `list` when JS
- add `index`, `count` method for range

## Patches for Nim-compatibility

