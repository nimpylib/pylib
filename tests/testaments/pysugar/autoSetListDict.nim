discard """
  output: '''
1
1
1
'''
"""

import pylib


def g():
    values = [
        complex(5.0, 12.0),
    ]
    aset = {5, 6}

    v = values[0]

    d = {
      "v": v ** 1
    }
    
    ls = [
        "\ud800"
    ]

    print(int(type(aset.pop()) == int))
    print(int(type(ls[0]) == type(u"")))
    print(int(d["v"] == v))


g()

