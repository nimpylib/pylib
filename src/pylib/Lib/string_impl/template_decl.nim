
type Template* = ref object of RootObj
  `template`*: string

func `$`*(self: Template): string = self.`template`

method delimiter*(self: Template): char{.base.} = '$'  ## \
## .. note:: In Python this is a class attribute
