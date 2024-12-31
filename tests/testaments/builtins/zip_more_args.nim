discard """
  output: '''
(1, 1, 1)
(2, 2, 2)
(3, 3, 3)
(1,)
(2,)
(3,)
true
'''
  
  #disable: defined(pylibDisableMoreArgsZip)  XXX: not work
"""

import pylib/builtins/iters

let l = 1..3

for i in zip(l, l, l): echo i
for i in zip(l): echo i
echo compiles(zip(l, strict=false))

