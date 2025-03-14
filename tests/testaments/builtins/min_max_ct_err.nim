discard """
  matrix: "--hints:off --errorMax:0 --styleCheck:error"
"""


import pylib/builtins/min_max


min() #[tt.Error
   ^ TypeError: min expected at least 1 argument, got 0]#

max() #[tt.Error
   ^ TypeError: max expected at least 1 argument, got 0]#

max(1)#[tt.Error
    ^ TypeError: 'int' object is not iterable]#

min(1)#[tt.Error
    ^ TypeError: 'int' object is not iterable]#
