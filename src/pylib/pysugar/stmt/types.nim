
type
  PySyntaxProcesser* = concept var self  ## One implememted is 
                                          ## `PyAsgnRewriter` in ./frame
                                          ## while its parsePyBody is in ./tonim
    parsePyBodyWithDoc(self, NimNode) is NimNode
    self.supportGenerics is bool
    self.dedentDoc is bool
