# v0.9.11 - 2025-06-26

## Bug Fixes
- py:
  - disallow noParnMultiExecInExcept before Python3.14. (d8a2ca3c4)
- dict: `xxx = dict.values/keys/items()` not compile. (d1a3521e9)
- windows:
  - break(mywinlean): fix winlean type inconsistent with Windowns.h, e.g. HANDLE. (c27d1848e)

## Feature additions
bump-pyversion: 3.14.0. (2804b347c)

### Chores:
- ci: trigger docs on tags v*.*. (87443468d)
- nimble: fix(windows): changelog not work. (9f9955828)

### EXT
- @range,list(@-able). (6c62b9e43)
