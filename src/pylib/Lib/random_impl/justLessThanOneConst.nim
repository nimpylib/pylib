## replace `justLessThanOne`_ declaration with hard-coded constant
##  if you wanna get rid of `n_math` dependence

from ../../Lib/n_math import nextafter
const justLessThanOne* = nextafter(1.0, 0.0)
